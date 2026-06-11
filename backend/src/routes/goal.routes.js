const express = require('express');
const router = express.Router();
const goalController = require('../controllers/goal.controller');
const authMiddleware = require('../middleware/auth');

// Apply auth middleware to all goal routes
router.use(authMiddleware);

// Define routes
router.post('/', goalController.createGoal);
router.get('/', goalController.getGoals);
router.put('/:id', goalController.updateGoal);
router.delete('/:id', goalController.deleteGoal);

module.exports = router;
