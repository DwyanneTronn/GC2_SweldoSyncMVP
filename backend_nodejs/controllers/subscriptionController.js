const Subscription = require('../models/Subscription');
const Company = require('../models/Company');

const PLAN_PRICES = {
  basic: 999,
  professional: 2499,
  enterprise: 4999
};

// Get subscription plans
exports.getPlans = async (req, res) => {
  res.json({
    plans: [
      {
        id: 'basic',
        name: 'Basic',
        price: PLAN_PRICES.basic,
        features: ['Up to 50 employees', 'Standard payroll calculation', 'Email support']
      },
      {
        id: 'professional',
        name: 'Professional',
        price: PLAN_PRICES.professional,
        features: ['Up to 200 employees', 'All industry templates', 'Priority support', 'Payroll history']
      },
      {
        id: 'enterprise',
        name: 'Enterprise',
        price: PLAN_PRICES.enterprise,
        features: ['Unlimited employees', 'Custom calculations', 'Dedicated support', 'API access']
      }
    ]
  });
};

// Create subscription (checkout)
exports.createSubscription = async (req, res) => {
  try {
    const { plan, paymentMethod } = req.body;

    if (!plan || !PLAN_PRICES[plan]) {
      return res.status(400).json({ error: 'Invalid plan selected' });
    }

    // Check if company already has an active subscription
    const existingSubscription = await Subscription.findOne({
      company: req.company._id,
      status: 'active'
    });

    if (existingSubscription) {
      return res.status(400).json({ error: 'Company already has an active subscription' });
    }

    // Calculate end date (1 month from now)
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + 1);

    const subscription = new Subscription({
      company: req.company._id,
      plan,
      price: PLAN_PRICES[plan],
      paymentMethod: paymentMethod || 'credit_card',
      status: 'pending',
      endDate
    });

    await subscription.save();

    // Update company with subscription
    await Company.findByIdAndUpdate(req.company._id, {
      subscription: subscription._id
    });

    res.status(201).json({
      subscription,
      message: 'Subscription created. Payment processing...'
    });
  } catch (error) {
    console.error('Create subscription error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get current subscription
exports.getSubscription = async (req, res) => {
  try {
    const subscription = await Subscription.findOne({
      company: req.company._id
    }).populate('company');

    if (!subscription) {
      return res.status(404).json({ error: 'No subscription found' });
    }

    res.json({ subscription });
  } catch (error) {
    console.error('Get subscription error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Update payment status (simulated payment processing)
exports.updatePaymentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { paymentStatus } = req.body;

    if (!['paid', 'pending', 'failed'].includes(paymentStatus)) {
      return res.status(400).json({ error: 'Invalid payment status' });
    }

    const subscription = await Subscription.findOneAndUpdate(
      { _id: id, company: req.company._id },
      { 
        paymentStatus,
        status: paymentStatus === 'paid' ? 'active' : 'pending'
      },
      { new: true }
    );

    if (!subscription) {
      return res.status(404).json({ error: 'Subscription not found' });
    }

    res.json({ subscription });
  } catch (error) {
    console.error('Update payment status error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Cancel subscription
exports.cancelSubscription = async (req, res) => {
  try {
    const subscription = await Subscription.findOneAndUpdate(
      { company: req.company._id },
      { status: 'cancelled' },
      { new: true }
    );

    if (!subscription) {
      return res.status(404).json({ error: 'No subscription found' });
    }

    res.json({ subscription, message: 'Subscription cancelled' });
  } catch (error) {
    console.error('Cancel subscription error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

