const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
  company: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    unique: true
  },
  plan: {
    type: String,
    enum: ['basic', 'professional', 'enterprise'],
    required: true
  },
  price: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['active', 'cancelled', 'expired', 'pending'],
    default: 'pending'
  },
  startDate: {
    type: Date,
    default: Date.now
  },
  endDate: {
    type: Date
  },
  paymentMethod: {
    type: String,
    enum: ['credit_card', 'bank_transfer', 'paypal'],
    default: 'credit_card'
  },
  paymentStatus: {
    type: String,
    enum: ['paid', 'pending', 'failed'],
    default: 'pending'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Subscription', subscriptionSchema);

