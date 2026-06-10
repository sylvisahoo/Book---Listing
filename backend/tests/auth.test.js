const request = require('supertest');
const app = require('../src/app');
const db = require('../src/db');

beforeEach(async () => {
  await db.query('DELETE FROM password_resets');
  await db.query('DELETE FROM token_blacklist');
  await db.query('DELETE FROM users');
});

afterAll(async () => {
  await db.pool.end();
});

describe('Authentication Module APIs', () => {
  const testUser = {
    name: 'John Doe',
    email: 'john@example.com',
    password: 'password123',
    confirmPassword: 'password123',
  };

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully with valid details', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send(testUser);

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('token');
      expect(res.body.user).toHaveProperty('id');
      expect(res.body.user.name).toBe(testUser.name);
      expect(res.body.user.email).toBe(testUser.email);
    });

    it('should not register user with missing details', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'test@example.com',
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should not register user when passwords do not match', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          ...testUser,
          confirmPassword: 'differentpassword',
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Passwords do not match');
    });

    it('should prevent registration with duplicate email', async () => {
      await request(app)
        .post('/api/auth/register')
        .send(testUser);

      const res = await request(app)
        .post('/api/auth/register')
        .send(testUser);

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Email already in use');
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      await request(app)
        .post('/api/auth/register')
        .send(testUser);
    });

    it('should login successfully with valid credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password,
        });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body.user.email).toBe(testUser.email);
    });

    it('should reject login with invalid password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: 'wrongpassword',
        });

      expect(res.status).toBe(401);
      expect(res.body).toHaveProperty('error', 'Invalid email or password');
    });

    it('should reject login with non-existent email', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'wrongemail@example.com',
          password: testUser.password,
        });

      expect(res.status).toBe(401);
      expect(res.body).toHaveProperty('error', 'Invalid email or password');
    });
  });

  describe('Password Reset Flow', () => {
    beforeEach(async () => {
      await request(app)
        .post('/api/auth/register')
        .send(testUser);
    });

    it('should generate reset token for valid email', async () => {
      const res = await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: testUser.email });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('message', 'Password reset token generated successfully');
    });

    it('should return 404 when requesting password reset for non-existent email', async () => {
      const res = await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: 'nonexistent@example.com' });

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('error', 'Email not found');
    });

    it('should reset password successfully using a valid token', async () => {
      const forgotRes = await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: testUser.email });
      const resetToken = forgotRes.body.token;

      const resetRes = await request(app)
        .post('/api/auth/reset-password')
        .send({
          token: resetToken,
          newPassword: 'newpassword123',
          confirmPassword: 'newpassword123',
        });

      expect(resetRes.status).toBe(200);
      expect(resetRes.body).toHaveProperty('message', 'Password reset successfully');

      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: 'newpassword123',
        });
      expect(loginRes.status).toBe(200);
      expect(loginRes.body).toHaveProperty('token');
    });

    it('should reject password reset if token is invalid', async () => {
      const res = await request(app)
        .post('/api/auth/reset-password')
        .send({
          token: 'invalid-token-value',
          newPassword: 'newpassword123',
          confirmPassword: 'newpassword123',
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid or expired reset token');
    });
  });

  describe('Session Management & Logout', () => {
    let token;

    beforeEach(async () => {
      const registerRes = await request(app)
        .post('/api/auth/register')
        .send(testUser);
      token = registerRes.body.token;
    });

    it('should access profile with valid token', async () => {
      const res = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.user.email).toBe(testUser.email);
    });

    it('should logout and invalidate the session/token successfully', async () => {
      const logoutRes = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${token}`);

      expect(logoutRes.status).toBe(200);
      expect(logoutRes.body).toHaveProperty('message', 'Logged out successfully');

      const profileRes = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${token}`);

      expect(profileRes.status).toBe(401);
      expect(profileRes.body).toHaveProperty('error', 'Session invalidated');
    });
  });
});
