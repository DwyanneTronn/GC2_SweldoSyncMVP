const express = require('express');
const router = express.Router();
const payrollController = require('../controllers/payrollController');
const authMiddleware = require('../middleware/auth');

router.post('/calculate', authMiddleware, payrollController.calculatePayroll);
router.get('/history', authMiddleware, payrollController.getPayrollHistory);
router.put('/:id/approve', authMiddleware, payrollController.approvePayroll);

module.exports = router;

