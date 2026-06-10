const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboard.controller');
const authMiddleware = require('../middleware/auth');

// Apply auth middleware to all dashboard routes
router.use(authMiddleware);

// Define routes
router.get('/stats', dashboardController.getDashboardStats);

module.exports = router;
