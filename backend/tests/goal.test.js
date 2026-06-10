const request = require('supertest');
const app = require('../src/app');
const db = require('../src/db');

let userToken1;
let userToken2;

beforeAll(async () => {
  await db.query('DELETE FROM goals');
  await db.query('DELETE FROM books');
  await db.query('DELETE FROM users');

  const res1 = await request(app)
    .post('/api/auth/register')
    .send({
      name: 'User One',
      email: 'user1@example.com',
      password: 'password123',
      confirmPassword: 'password123',
    });
  userToken1 = res1.body.token;

  const res2 = await request(app)
    .post('/api/auth/register')
    .send({
      name: 'User Two',
      email: 'user2@example.com',
      password: 'password123',
      confirmPassword: 'password123',
    });
  userToken2 = res2.body.token;
});

beforeEach(async () => {
  await db.query('DELETE FROM goals');
  await db.query('DELETE FROM books');
});

afterAll(async () => {
  await db.query('DELETE FROM goals');
  await db.query('DELETE FROM books');
  await db.query('DELETE FROM users');
  await db.pool.end();
});

describe('Reading Goals Module APIs', () => {
  describe('POST /api/goals (Create Goal)', () => {
    it('should create a reading goal successfully with default current year', async () => {
      const currentYear = new Date().getFullYear();
      const res = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          target_books: 12
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('message', 'Goal created successfully');
      expect(res.body.goal.year).toBe(currentYear);
      expect(res.body.goal.targetBooks).toBe(12);
      expect(res.body.goal.completedBooks).toBe(0);
      expect(res.body.goal.progressPercentage).toBe(0);
      expect(res.body.goal.status).toBe('Not Started');
    });

    it('should create a reading goal for a custom year', async () => {
      const res = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          year: 2025,
          target_books: 20
        });

      expect(res.status).toBe(201);
      expect(res.body.goal.year).toBe(2025);
      expect(res.body.goal.targetBooks).toBe(20);
    });

    it('should reject goal creation when target_books is missing', async () => {
      const res = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          year: 2026
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Target books is required');
    });

    it('should reject zero target books', async () => {
      const res = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          target_books: 0
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Goal value must be greater than zero');
    });

    it('should reject negative target books', async () => {
      const res = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          target_books: -5
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Goal value must be greater than zero');
    });

    it('should prevent duplicate goals for the same year', async () => {
      await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          year: 2026,
          target_books: 10
        });

      const res = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          year: 2026,
          target_books: 15
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Goal already exists for this year');
    });
  });

  describe('GET /api/goals (Retrieve Goals List & Auto-calculated Progress)', () => {
    it('should calculate "In Progress" and progress percentage correctly', async () => {
      const currentYear = new Date().getFullYear();
      await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          year: currentYear,
          target_books: 4
        });

      const todayStr = new Date().toISOString().split('T')[0];
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Finished Book',
          author: 'Author',
          genre: 'Fiction',
          publication_year: 2000,
          shelf: 'Finished Reading',
          completion_date: todayStr,
          rating: 4
        });

      const res = await request(app)
        .get('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.goals.length).toBe(1);
      expect(res.body.goals[0].completedBooks).toBe(1);
      expect(res.body.goals[0].progressPercentage).toBe(25);
      expect(res.body.goals[0].status).toBe('In Progress');
    });

    it('should calculate "Achieved" status when completed books meet or exceed target', async () => {
      const currentYear = new Date().getFullYear();
      await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          year: currentYear,
          target_books: 1
        });

      const todayStr = new Date().toISOString().split('T')[0];
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Finished Book',
          author: 'Author',
          genre: 'Fiction',
          publication_year: 2000,
          shelf: 'Finished Reading',
          completion_date: todayStr,
          rating: 4
        });

      const res = await request(app)
        .get('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.goals[0].completedBooks).toBe(1);
      expect(res.body.goals[0].progressPercentage).toBe(100);
      expect(res.body.goals[0].status).toBe('Achieved');
    });
  });

  describe('PUT /api/goals/:id (Update Goal Target)', () => {
    it('should update target books value of own goal successfully', async () => {
      const createRes = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          year: 2026,
          target_books: 10
        });

      const goalId = createRes.body.goal.id;

      const res = await request(app)
        .put(`/api/goals/${goalId}`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          target_books: 15
        });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message', 'Goal updated successfully');
      expect(res.body.goal.targetBooks).toBe(15);
    });

    it('should reject goal update with negative value', async () => {
      const createRes = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          year: 2026,
          target_books: 10
        });

      const goalId = createRes.body.goal.id;

      const res = await request(app)
        .put(`/api/goals/${goalId}`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          target_books: -5
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Goal value must be greater than zero');
    });

    it('should prevent updating another user\'s goal', async () => {
      const createRes = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken2}`)
        .send({
          year: 2026,
          target_books: 10
        });

      const goalId = createRes.body.goal.id;

      const res = await request(app)
        .put(`/api/goals/${goalId}`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          target_books: 20
        });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('error', 'Access denied');
    });
  });
});
