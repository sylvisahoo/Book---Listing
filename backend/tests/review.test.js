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

describe('Ratings & Reviews Module APIs', () => {
  const testBook = {
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    genre: 'Fiction',
    publication_year: 1925,
  };

  describe('POST /api/books/:id/review (Mark Completed & Review)', () => {
    it('should submit rating and review successfully and move book to Finished Reading shelf', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .post(`/api/books/${bookId}/review`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          completion_date: '2026-06-01',
          rating: 5,
          review: 'An absolute masterpiece of American literature.',
        });

      expect(res.status).toBe(200);
      expect(res.body.book.shelf).toBe('Finished Reading');
      expect(res.body.book.rating).toBe(5);
      expect(res.body.book.review).toBe('An absolute masterpiece of American literature.');
      expect(res.body.book.completion_date).toBe('2026-06-01');

      const dbCheck = await db.query('SELECT shelf, rating, review, completion_date FROM books WHERE id = $1', [bookId]);
      expect(dbCheck.rows[0].shelf).toBe('Finished Reading');
      expect(dbCheck.rows[0].rating).toBe(5);
      expect(dbCheck.rows[0].review).toBe('An absolute masterpiece of American literature.');
      expect(dbCheck.rows[0].completion_date).toBe('2026-06-01');
    });

    it('should allow optional review text (rating and completion date only)', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .post(`/api/books/${bookId}/review`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          completion_date: '2026-06-02',
          rating: 4,
        });

      expect(res.status).toBe(200);
      expect(res.body.book.shelf).toBe('Finished Reading');
      expect(res.body.book.rating).toBe(4);
      expect(res.body.book.review).toBeNull();
    });

    it('should reject review when missing completion_date', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .post(`/api/books/${bookId}/review`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          rating: 4,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Completion date and rating are required');
    });

    it('should reject review when missing rating', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .post(`/api/books/${bookId}/review`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          completion_date: '2026-06-01',
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Completion date and rating are required');
    });

    it('should reject rating values outside 1-5 range', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .post(`/api/books/${bookId}/review`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          completion_date: '2026-06-01',
          rating: 6,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid rating. Must be between 1 and 5');
    });

    it('should reject completion date in the future', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;
      
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 2);
      const futureDateStr = futureDate.toISOString().split('T')[0];

      const res = await request(app)
        .post(`/api/books/${bookId}/review`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          completion_date: futureDateStr,
          rating: 5,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid completion date');
    });

    it('should reject reviews exceeding 2000 characters', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;
      const longReview = 'a'.repeat(2001);

      const res = await request(app)
        .post(`/api/books/${bookId}/review`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          completion_date: '2026-06-01',
          rating: 5,
          review: longReview,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Review exceeds maximum length of 2000 characters');
    });

    it('should prevent reviewing another user\'s book', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken2}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .post(`/api/books/${bookId}/review`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          completion_date: '2026-06-01',
          rating: 5,
        });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('error', 'Access denied to this book');
    });
  });

  describe('GET /api/books/:id (Retrieval Verification)', () => {
    it('should include ratings and reviews when retrieving book details', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      await request(app)
        .post(`/api/books/${bookId}/review`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          completion_date: '2026-06-01',
          rating: 5,
          review: 'Incredible book.',
        });

      const res = await request(app)
        .get(`/api/books/${bookId}`)
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.book.rating).toBe(5);
      expect(res.body.book.review).toBe('Incredible book.');
      expect(res.body.book.completion_date).toBe('2026-06-01');
    });
  });
});
