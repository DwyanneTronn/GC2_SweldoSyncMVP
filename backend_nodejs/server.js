// Main server file - refactored to be minimal and modular
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/database');
const { apiLimiter } = require('./middleware/rateLimiter');

// Import routes
const authRoutes = require('./routes/auth');
const employeeRoutes = require('./routes/employees');
const payrollRoutes = require('./routes/payroll');
const subscriptionRoutes = require('./routes/subscriptions');
const holidayRoutes = require('./routes/holidays');
const analyticsRoutes = require('./routes/analytics');

const app = express();
const port = process.env.PORT || 3000;

// Connect to database
connectDB();

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' })); // Limit request size
app.use(apiLimiter); // Apply rate limiting to all routes

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'SweldoSync API is running' });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/payroll', payrollRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/holidays', holidayRoutes);
app.use('/api/analytics', analyticsRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(port, () => {
  console.log(`SweldoSync Backend running on http://localhost:${port}`);
});
