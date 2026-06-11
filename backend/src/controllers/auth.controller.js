const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../db');
const { seedUserBooks } = require('../utils/userSeeder');

exports.register = async (req, res) => {
  try {
    const { name, email, password, confirmPassword } = req.body;

    if (!name || !email || !password || !confirmPassword) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    if (password !== confirmPassword) {
      return res.status(400).json({ error: 'Passwords do not match' });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    const userCheck = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Email already in use' });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const result = await db.query(
      'INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3) RETURNING id, name, email, created_at',
      [name, email, passwordHash]
    );

    const newUser = result.rows[0];

    // Seed default books automatically for the newly registered user
    try {
      await seedUserBooks(newUser.id);
    } catch (seedingError) {
      console.error('Failed to seed default books for new user:', seedingError);
    }

    const token = jwt.sign(
      { id: newUser.id, email: newUser.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.status(201).json({
      message: 'Registration successful',
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        createdAt: newUser.created_at,
      },
      token,
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = result.rows[0];

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.status(200).json({
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
      token,
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};

exports.logout = async (req, res) => {
  try {
    const token = req.token;
    const expiry = req.user.exp ? new Date(req.user.exp * 1000) : new Date(Date.now() + 24 * 60 * 60 * 1000);

    await db.query(
      'INSERT INTO token_blacklist (token, expires_at) VALUES ($1, $2) ON CONFLICT (token) DO NOTHING',
      [token, expiry]
    );

    return res.status(200).json({ message: 'Logged out successfully' });
  } catch (error) {
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const userResult = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Email not found' });
    }

    const user = userResult.rows[0];

    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await db.query(
      'INSERT INTO password_resets (user_id, token, expires_at) VALUES ($1, $2, $3)',
      [user.id, token, expiresAt]
    );

    return res.status(200).json({
      message: 'Password reset token generated successfully',
      token,
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const { token, newPassword, confirmPassword } = req.body;

    if (!token || !newPassword || !confirmPassword) {
      return res.status(400).json({ error: 'Token, new password, and confirm password are required' });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({ error: 'Passwords do not match' });
    }

    const resetResult = await db.query(
      'SELECT * FROM password_resets WHERE token = $1 AND expires_at > NOW()',
      [token]
    );

    if (resetResult.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid or expired reset token' });
    }

    const reset = resetResult.rows[0];

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [passwordHash, reset.user_id]);
    await db.query('DELETE FROM password_resets WHERE user_id = $1', [reset.user_id]);

    return res.status(200).json({ message: 'Password reset successfully' });
  } catch (error) {
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const result = await db.query('SELECT id, name, email, created_at FROM users WHERE id = $1', [req.user.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    return res.status(200).json({ user: result.rows[0] });
  } catch (error) {
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};
