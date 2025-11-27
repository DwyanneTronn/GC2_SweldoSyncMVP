const PayrollRun = require('../models/PayrollRun');
const Subscription = require('../models/Subscription');
const Company = require('../models/Company');
const Employee = require('../models/Employee');
const User = require('../models/User');

// Get analytics dashboard data
exports.getDashboardAnalytics = async (req, res) => {
  try {
    if (!req.company || !req.company._id) {
      return res.status(400).json({ error: 'Company information not found' });
    }

    const companyId = req.company._id;
    const { startDate, endDate } = req.query;

    // Build date filter
    const dateFilter = {};
    if (startDate || endDate) {
      dateFilter.createdAt = {};
      if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
      if (endDate) dateFilter.createdAt.$lte = new Date(endDate);
    }

    // Payroll Analytics
    const payrollRuns = await PayrollRun.find({
      company: companyId,
      ...dateFilter
    });

    const totalPayrollCost = payrollRuns.reduce((sum, run) => sum + (run.totalCost || 0), 0);
    const totalPayrollRuns = payrollRuns.length;
    const averagePayrollCost = totalPayrollRuns > 0 ? totalPayrollCost / totalPayrollRuns : 0;

    // Payroll by status
    const payrollByStatus = payrollRuns.reduce((acc, run) => {
      const status = run.status || 'unknown';
      acc[status] = (acc[status] || 0) + 1;
      return acc;
    }, {});

    // Payroll by industry
    const payrollByIndustry = payrollRuns.reduce((acc, run) => {
      const industry = run.industry || 'unknown';
      acc[industry] = (acc[industry] || 0) + 1;
      return acc;
    }, {});

    // Monthly payroll trends (last 6 months)
    const monthlyTrends = [];
    const now = new Date();
    for (let i = 5; i >= 0; i--) {
      const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);
      
      const monthRuns = payrollRuns.filter(run => {
        const runDate = new Date(run.createdAt);
        return runDate >= monthStart && runDate <= monthEnd;
      });
      
      const monthTotal = monthRuns.reduce((sum, run) => sum + (run.totalCost || 0), 0);
      
      monthlyTrends.push({
        month: monthStart.toLocaleString('default', { month: 'short', year: 'numeric' }),
        total: monthTotal,
        count: monthRuns.length
      });
    }

    // Employee Statistics
    const totalEmployees = await Employee.countDocuments({ company: companyId, isActive: true });
    
    // Subscription Statistics
    let subscriptionStats = null;
    try {
      const subscription = await Subscription.findOne({ company: companyId });
      if (subscription) {
        subscriptionStats = {
          plan: subscription.plan,
          status: subscription.status,
          price: subscription.price,
          paymentStatus: subscription.paymentStatus
        };
      }
    } catch (subError) {
      console.error('Error fetching subscription:', subError);
      // Continue without subscription stats
    }

    // Recent Activity (last 5 payroll runs)
    const recentActivity = payrollRuns
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 5)
      .map(run => ({
        id: run._id,
        payPeriod: run.payPeriod || 'Unknown',
        totalCost: run.totalCost || 0,
        status: run.status || 'unknown',
        industry: run.industry || 'unknown',
        createdAt: run.createdAt,
        employeeCount: (run.payslips && run.payslips.length) || 0
      }));

    res.json({
      payroll: {
        totalCost: totalPayrollCost,
        totalRuns: totalPayrollRuns,
        averageCost: averagePayrollCost,
        byStatus: payrollByStatus,
        byIndustry: payrollByIndustry,
        monthlyTrends: monthlyTrends
      },
      employees: {
        total: totalEmployees
      },
      subscription: subscriptionStats,
      recentActivity: recentActivity
    });
  } catch (error) {
    console.error('Analytics error:', error);
    res.status(500).json({ 
      error: 'Server error fetching analytics',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get all companies analytics (admin only)
exports.getAllCompaniesAnalytics = async (req, res) => {
  try {
    // Get all companies
    const companies = await Company.find().populate({
      path: 'subscription',
      model: 'Subscription'
    });
    
    // Get all payroll runs
    const allPayrollRuns = await PayrollRun.find();
    
    // Calculate totals
    const totalRevenue = companies.reduce((sum, company) => {
      if (company.subscription && company.subscription.status === 'active') {
        return sum + (company.subscription.price || 0);
      }
      return sum;
    }, 0);

    const totalCompanies = companies.length;
    const activeSubscriptions = companies.filter(c => 
      c.subscription && c.subscription.status === 'active'
    ).length;

    const totalPayrollProcessed = allPayrollRuns.reduce((sum, run) => 
      sum + (run.totalCost || 0), 0
    );

    // Subscription by plan
    const subscriptionsByPlan = companies.reduce((acc, company) => {
      if (company.subscription) {
        const plan = company.subscription.plan;
        acc[plan] = (acc[plan] || 0) + 1;
      }
      return acc;
    }, {});

    res.json({
      overview: {
        totalCompanies,
        activeSubscriptions,
        totalRevenue,
        totalPayrollProcessed
      },
      subscriptionsByPlan,
      companies: companies.map(c => ({
        id: c._id,
        name: c.name,
        industry: c.industry,
        subscription: c.subscription ? {
          plan: c.subscription.plan,
          status: c.subscription.status
        } : null
      }))
    });
  } catch (error) {
    console.error('Admin analytics error:', error);
    res.status(500).json({ error: 'Server error fetching admin analytics' });
  }
};

