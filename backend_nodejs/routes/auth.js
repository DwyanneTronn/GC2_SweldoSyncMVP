const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');

// Validation middleware
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

router.post('/register', 
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('companyName').trim().notEmpty().withMessage('Company name is required'),
    body('industry').isIn(['standard', 'bpo', 'airline']).withMessage('Invalid industry'),
  ],
  validate,
  authController.register
);

router.post('/login', 
  authLimiter, // Brute force protection
  [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  validate,
  authController.login
);

router.get('/me', authMiddleware, authController.getMe);

module.exports = router;

