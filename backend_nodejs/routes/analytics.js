const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const authMiddleware = require('../middleware/auth');
const roleMiddleware = require('../middleware/roleCheck');

router.get('/dashboard', authMiddleware, analyticsController.getDashboardAnalytics);
router.get('/admin', authMiddleware, roleMiddleware('admin'), analyticsController.getAllCompaniesAnalytics);

module.exports = router;

