const mongoose = require('mongoose');

const payrollRunSchema = new mongoose.Schema({
  company: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true
  },
  payPeriod: {
    type: String,
    required: true
  },
  industry: {
    type: String,
    enum: ['standard', 'bpo', 'airline'],
    required: true
  },
  payslips: [{
    employee: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Employee',
      required: true
    },
    employeeName: String,
    basicEarned: Number,
    variablePay: Number,
    variableLabel: String,
    deductions: Number,
    netPay: Number,
    inputs: {
      val1: Number,
      val2: Number,
      val3: Number
    }
  }],
  totalCost: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['draft', 'calculated', 'approved', 'disbursed'],
    default: 'draft'
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  approvedAt: Date,
  disbursedAt: Date
});

module.exports = mongoose.model('PayrollRun', payrollRunSchema);

