const jwt = require('jsonwebtoken');
const db = require('../db');

module.exports = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Access token is required' });
  }

  const token = authHeader.split(' ')[1];
  try {
    // Verify if token is blacklisted
    const blacklistCheck = await db.query('SELECT * FROM token_blacklist WHERE token = $1', [token]);
    if (blacklistCheck.rows.length > 0) {
      return res.status(401).json({ error: 'Session invalidated' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if user still exists in the database
    const userCheck = await db.query('SELECT id FROM users WHERE id = $1', [decoded.id]);
    if (userCheck.rows.length === 0) {
      return res.status(401).json({ error: 'User account not found. Please sign in again.' });
    }

    req.user = decoded;
    req.token = token;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};
