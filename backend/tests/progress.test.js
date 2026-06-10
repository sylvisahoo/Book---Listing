const request = require('supertest');
const app = require('../src/app');
const db = require('../src/db');

let userToken1;
let userToken2;

beforeAll(async () => {
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
  await db.query('DELETE FROM books');
});

afterAll(async () => {
  await db.query('DELETE FROM books');
  await db.query('DELETE FROM users');
  await db.pool.end();
});

describe('Reading Progress Tracking Module APIs', () => {
  const testBook = {
    title: 'The Hobbit',
    author: 'J.R.R. Tolkien',
    genre: 'Fantasy',
    publication_year: 1937,
    shelf: 'Currently Reading',
  };

  describe('PATCH /api/books/:id/progress (Update Progress)', () => {
    it('should update progress successfully for "Currently Reading" book', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/progress`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          current_page: 50,
          total_pages: 300,
        });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message', 'Reading progress updated successfully');
      expect(res.body.book.current_page).toBe(50);
      expect(res.body.book.total_pages).toBe(300);
      expect(res.body.progress_percentage).toBe(16.67);

      const dbCheck = await db.query('SELECT current_page, total_pages FROM books WHERE id = $1', [bookId]);
      expect(dbCheck.rows[0].current_page).toBe(50);
      expect(dbCheck.rows[0].total_pages).toBe(300);
    });

    it('should calculate 0% progress if total pages is 0', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/progress`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          current_page: 0,
          total_pages: 0,
        });

      expect(res.status).toBe(200);
      expect(res.body.progress_percentage).toBe(0);
    });

    it('should reject progress update if missing current_page or total_pages', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/progress`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          current_page: 50,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Current page and total pages are required');
    });

    it('should reject negative current page', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/progress`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          current_page: -1,
          total_pages: 300,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid current page number');
    });

    it('should reject negative total pages', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/progress`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          current_page: 10,
          total_pages: -300,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid total pages number');
    });

    it('should reject progress if current page exceeds total pages', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/progress`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          current_page: 350,
          total_pages: 300,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Current page cannot exceed total pages');
    });

    it('should reject progress update if book is on a shelf other than "Currently Reading"', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          ...testBook,
          shelf: 'Want To Read',
        });

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/progress`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          current_page: 50,
          total_pages: 300,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Progress tracking is only available for books currently being read');
    });

    it('should prevent updating progress on another user\'s book', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken2}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/progress`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          current_page: 50,
          total_pages: 300,
        });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('error', 'Access denied to this book');
    });
  });
});
