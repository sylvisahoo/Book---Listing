const db = require('../db');
const { mapDatabaseError } = require('../utils/errorHandler');

// Helper to calculate progress and status for a goal
async function getGoalProgress(userId, year, targetBooks) {
  const completedResult = await db.query(
    `SELECT COUNT(*) 
     FROM books 
     WHERE user_id = $1 
       AND shelf = 'Finished Reading' 
       AND completion_date IS NOT NULL 
       AND EXTRACT(YEAR FROM completion_date) = $2`,
    [userId, year]
  );

  const completedBooks = parseInt(completedResult.rows[0].count, 10);
  const progressPercentage = targetBooks > 0 ? parseFloat(((completedBooks / targetBooks) * 100).toFixed(2)) : 0;

  let status = 'Not Started';
  if (completedBooks > 0) {
    if (completedBooks >= targetBooks) {
      status = 'Achieved';
    } else {
      status = 'In Progress';
    }
  }

  return {
    completedBooks,
    progressPercentage,
    status
  };
}

exports.createGoal = async (req, res) => {
  try {
    const userId = req.user.id;
    const { year, target_books } = req.body;

    if (target_books === undefined || target_books === null) {
      return res.status(400).json({ error: 'Target books is required' });
    }

    const target = parseInt(target_books, 10);
    if (isNaN(target) || target <= 0) {
      return res.status(400).json({ error: 'Goal value must be greater than zero' });
    }

    const targetYear = year ? parseInt(year, 10) : new Date().getFullYear();
    if (isNaN(targetYear)) {
      return res.status(400).json({ error: 'Invalid year value' });
    }

    const existCheck = await db.query(
      'SELECT * FROM goals WHERE user_id = $1 AND year = $2',
      [userId, targetYear]
    );

    if (existCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Goal already exists for this year' });
    }

    const insertResult = await db.query(
      'INSERT INTO goals (user_id, year, target_books) VALUES ($1, $2, $3) RETURNING *',
      [userId, targetYear, target]
    );

    const goal = insertResult.rows[0];
    const details = await getGoalProgress(userId, goal.year, goal.target_books);

    return res.status(201).json({
      message: 'Goal created successfully',
      goal: {
        id: goal.id,
        year: goal.year,
        targetBooks: goal.target_books,
        createdAt: goal.created_at,
        ...details
      }
    });
  } catch (error) {
    console.error('Error in createGoal:', error);
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Goal already exists for this year' });
    }
    if (error.code === '23514') {
      return res.status(400).json({ error: 'Goal value must be greater than zero' });
    }
    const mapped = mapDatabaseError(error, 'Reading goal creation failed. Please try again.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.getGoals = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await db.query(
      'SELECT * FROM goals WHERE user_id = $1 ORDER BY year DESC',
      [userId]
    );

    const goalsWithProgress = [];
    for (const goal of result.rows) {
      const details = await getGoalProgress(userId, goal.year, goal.target_books);
      goalsWithProgress.push({
        id: goal.id,
        year: goal.year,
        targetBooks: goal.target_books,
        createdAt: goal.created_at,
        ...details
      });
    }

    return res.status(200).json({ goals: goalsWithProgress });
  } catch (error) {
    console.error('Error in getGoals:', error);
    const mapped = mapDatabaseError(error, 'Failed to retrieve goals.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.updateGoal = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { target_books } = req.body;

    if (target_books === undefined || target_books === null) {
      return res.status(400).json({ error: 'Target books is required' });
    }

    const target = parseInt(target_books, 10);
    if (isNaN(target) || target <= 0) {
      return res.status(400).json({ error: 'Goal value must be greater than zero' });
    }

    const goalResult = await db.query(
      'SELECT * FROM goals WHERE id = $1',
      [id]
    );

    if (goalResult.rows.length === 0) {
      return res.status(404).json({ error: 'Goal not found' });
    }

    const goal = goalResult.rows[0];
    if (goal.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updateResult = await db.query(
      'UPDATE goals SET target_books = $1 WHERE id = $2 RETURNING *',
      [target, id]
    );

    const updatedGoal = updateResult.rows[0];
    const details = await getGoalProgress(userId, updatedGoal.year, updatedGoal.target_books);

    return res.status(200).json({
      message: 'Goal updated successfully',
      goal: {
        id: updatedGoal.id,
        year: updatedGoal.year,
        targetBooks: updatedGoal.target_books,
        createdAt: updatedGoal.created_at,
        ...details
      }
    });
  } catch (error) {
    console.error('Error in updateGoal:', error);
    if (error.code === '23514') {
      return res.status(400).json({ error: 'Goal value must be greater than zero' });
    }
    const mapped = mapDatabaseError(error, 'Failed to update goal.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.deleteGoal = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const goalResult = await db.query(
      'SELECT * FROM goals WHERE id = $1',
      [id]
    );

    if (goalResult.rows.length === 0) {
      return res.status(404).json({ error: 'Goal not found' });
    }

    const goal = goalResult.rows[0];
    if (goal.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await db.query('DELETE FROM goals WHERE id = $1', [id]);

    return res.status(200).json({
      message: 'Goal deleted successfully'
    });
  } catch (error) {
    console.error('Error in deleteGoal:', error);
    const mapped = mapDatabaseError(error, 'Failed to delete goal.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

module.exports.getGoalProgress = getGoalProgress;
