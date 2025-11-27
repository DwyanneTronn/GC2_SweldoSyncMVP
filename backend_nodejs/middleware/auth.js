const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authMiddleware = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided, authorization denied' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key-change-in-production');
    const user = await User.findById(decoded.userId).populate('company');
    
    if (!user) {
      return res.status(401).json({ error: 'Token is not valid' });
    }

    req.user = user;
    req.company = user.company;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Token is not valid' });
  }
};

module.exports = authMiddleware;

