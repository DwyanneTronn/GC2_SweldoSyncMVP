const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');
const authMiddleware = require('../middleware/auth');

router.get('/plans', subscriptionController.getPlans);
router.get('/', authMiddleware, subscriptionController.getSubscription);
router.post('/', authMiddleware, subscriptionController.createSubscription);
router.put('/:id/payment', authMiddleware, subscriptionController.updatePaymentStatus);
router.delete('/', authMiddleware, subscriptionController.cancelSubscription);

module.exports = router;

