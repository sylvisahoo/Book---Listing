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

describe('Reading Status Management (Shelves)', () => {
  const testBook = {
    title: 'Test Book',
    author: 'Author',
    genre: 'Genre',
    publication_year: 2020,
  };

  describe('Shelf Assignment', () => {
    it('should assign a default shelf of "Want To Read" when creating a book', async () => {
      const res = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      expect(res.status).toBe(201);
      expect(res.body.book.shelf).toBe('Want To Read');
    });

    it('should allow setting a custom shelf on creation', async () => {
      const res = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          ...testBook,
          shelf: 'Currently Reading',
        });

      expect(res.status).toBe(201);
      expect(res.body.book.shelf).toBe('Currently Reading');
    });

    it('should reject invalid custom shelf on creation', async () => {
      const res = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          ...testBook,
          shelf: 'Invalid Shelf Name',
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid shelf value');
    });

    it('should move a book to Want To Read shelf successfully', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ ...testBook, shelf: 'Currently Reading' });

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/shelf`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ shelf: 'Want To Read' });

      expect(res.status).toBe(200);
      expect(res.body.book.shelf).toBe('Want To Read');

      const dbCheck = await db.query('SELECT shelf FROM books WHERE id = $1', [bookId]);
      expect(dbCheck.rows[0].shelf).toBe('Want To Read');
    });

    it('should move a book to Currently Reading shelf successfully', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/shelf`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ shelf: 'Currently Reading' });

      expect(res.status).toBe(200);
      expect(res.body.book.shelf).toBe('Currently Reading');
    });

    it('should move a book to Finished Reading shelf successfully', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/shelf`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ shelf: 'Finished Reading' });

      expect(res.status).toBe(200);
      expect(res.body.book.shelf).toBe('Finished Reading');
    });

    it('should reject invalid shelf values on update', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/shelf`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ shelf: 'Invalid Shelf Value' });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid shelf value');
    });

    it('should prevent moving shelf of another user\'s book', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken2}`)
        .send(testBook);

      const bookId = addRes.body.book.id;

      const res = await request(app)
        .patch(`/api/books/${bookId}/shelf`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ shelf: 'Currently Reading' });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('error', 'Access denied to this book');
    });
  });

  describe('Shelf Statistics', () => {
    it('should calculate and return correct shelf statistics for authenticated user', async () => {
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ ...testBook, title: 'W1', shelf: 'Want To Read' });
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ ...testBook, title: 'W2', shelf: 'Want To Read' });

      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ ...testBook, title: 'CR1', shelf: 'Currently Reading' });

      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ ...testBook, title: 'FR1', shelf: 'Finished Reading' });
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ ...testBook, title: 'FR2', shelf: 'Finished Reading' });
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({ ...testBook, title: 'FR3', shelf: 'Finished Reading' });

      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken2}`)
        .send({ ...testBook, title: 'U2_FR', shelf: 'Finished Reading' });

      const res = await request(app)
        .get('/api/books/shelves/stats')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body).toEqual({
        wantToRead: 2,
        currentlyReading: 1,
        finishedReading: 3,
      });

      const res2 = await request(app)
        .get('/api/books/shelves/stats')
        .set('Authorization', `Bearer ${userToken2}`);

      expect(res2.status).toBe(200);
      expect(res2.body).toEqual({
        wantToRead: 0,
        currentlyReading: 0,
        finishedReading: 1,
      });
    });
  });
});
