const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Company = require('../models/Company');

const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET || 'your-secret-key-change-in-production', {
    expiresIn: '7d'
  });
};

// Register new company and user
exports.register = async (req, res) => {
  try {
    const { email, password, name, companyName, industry } = req.body;

    if (!email || !password || !name || !companyName || !industry) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Create company
    const company = new Company({
      name: companyName,
      industry
    });
    await company.save();

    // Create user
    const user = new User({
      email,
      password,
      name,
      company: company._id,
      role: 'admin'
    });
    await user.save();

    const token = generateToken(user._id);

    res.status(201).json({
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        role: user.role
      },
      company: {
        id: company._id,
        name: company.name,
        industry: company.industry
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Server error during registration' });
  }
};

// Login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await User.findOne({ email }).populate('company');
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = generateToken(user._id);

    res.json({
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        role: user.role
      },
      company: {
        id: user.company._id,
        name: user.company.name,
        industry: user.company.industry
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
};

// Get current user
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('company');
    res.json({
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        role: user.role
      },
      company: {
        id: user.company._id,
        name: user.company.name,
        industry: user.company.industry
      }
    });
  } catch (error) {
    console.error('Get me error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

