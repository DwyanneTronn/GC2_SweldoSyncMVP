const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const employeeController = require('../controllers/employeeController');
const authMiddleware = require('../middleware/auth');

// Validation middleware
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

router.get('/', authMiddleware, employeeController.getEmployees);
router.post('/', 
  authMiddleware,
  [
    body('employeeId').trim().notEmpty().withMessage('Employee ID is required'),
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('role').trim().notEmpty().withMessage('Role is required'),
    body('basicSalary').isFloat({ min: 0 }).withMessage('Basic salary must be a positive number'),
  ],
  validate,
  employeeController.createEmployee
);
router.put('/:id', 
  authMiddleware,
  [
    body('name').optional().trim().notEmpty(),
    body('role').optional().trim().notEmpty(),
    body('basicSalary').optional().isFloat({ min: 0 }),
  ],
  validate,
  employeeController.updateEmployee
);
router.delete('/:id', authMiddleware, employeeController.deleteEmployee);

module.exports = router;

