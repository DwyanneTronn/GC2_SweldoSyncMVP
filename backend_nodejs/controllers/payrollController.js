const Employee = require('../models/Employee');
const PayrollRun = require('../models/PayrollRun');
const { calculatePayroll } = require('../services/payrollService');

// Calculate payroll
exports.calculatePayroll = async (req, res) => {
  try {
    const { industry, employees, payPeriod } = req.body;

    if (!industry || !employees || !payPeriod) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Fetch employee data from database
    const employeeIds = employees.map(emp => emp.id || emp._id);
    const dbEmployees = await Employee.find({
      _id: { $in: employeeIds },
      company: req.company._id,
      isActive: true
    });

    if (dbEmployees.length !== employees.length) {
      return res.status(400).json({ error: 'Some employees not found' });
    }

    // Map database employees with input data
    const employeesWithInputs = dbEmployees.map(dbEmp => {
      const inputData = employees.find(emp => 
        (emp.id || emp._id).toString() === dbEmp._id.toString()
      );
      return {
        _id: dbEmp._id,
        name: dbEmp.name,
        basicSalary: dbEmp.basicSalary,
        inputs: inputData?.inputs || { val1: 0, val2: 0, val3: 0 }
      };
    });

    // Calculate payroll
    const result = await calculatePayroll(industry, employeesWithInputs, req.company._id);

    // Save payroll run to database
    const payrollRun = new PayrollRun({
      company: req.company._id,
      payPeriod,
      industry,
      payslips: result.payslips.map(p => ({
        employee: p.employeeId,
        employeeName: p.employeeName,
        basicEarned: p.basicEarned,
        variablePay: p.variablePay,
        variableLabel: p.variableLabel,
        deductions: p.deductions,
        netPay: p.netPay,
        inputs: p.inputs
      })),
      totalCost: result.totalCost,
      status: 'calculated',
      createdBy: req.user._id
    });

    await payrollRun.save();

    // Format response for Flutter app
    const formattedPayslips = result.payslips.map(p => ({
      id: p.employeeId,
      name: p.employeeName,
      basicEarned: p.basicEarned,
      variablePay: p.variablePay,
      variableLabel: p.variableLabel,
      deductions: p.deductions,
      netPay: p.netPay
    }));

    res.json({ 
      payslips: formattedPayslips,
      payrollRunId: payrollRun._id
    });
  } catch (error) {
    console.error('Calculate payroll error:', error);
    res.status(500).json({ error: 'An error occurred during calculation' });
  }
};

// Get payroll history
exports.getPayrollHistory = async (req, res) => {
  try {
    const payrollRuns = await PayrollRun.find({ 
      company: req.company._id 
    })
    .populate('createdBy', 'name email')
    .sort({ createdAt: -1 })
    .limit(50);

    res.json({ payrollRuns });
  } catch (error) {
    console.error('Get payroll history error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Approve payroll
exports.approvePayroll = async (req, res) => {
  try {
    const { id } = req.params;

    const payrollRun = await PayrollRun.findOneAndUpdate(
      { _id: id, company: req.company._id },
      { status: 'approved', approvedAt: Date.now() },
      { new: true }
    );

    if (!payrollRun) {
      return res.status(404).json({ error: 'Payroll run not found' });
    }

    res.json({ payrollRun });
  } catch (error) {
    console.error('Approve payroll error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

