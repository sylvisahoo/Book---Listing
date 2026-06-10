const request = require('supertest');
const fs = require('fs');
const path = require('path');
const app = require('../src/app');
const db = require('../src/db');

let userToken1;
let userToken2;
let userId1;
let userId2;

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
  userId1 = res1.body.user.id;

  const res2 = await request(app)
    .post('/api/auth/register')
    .send({
      name: 'User Two',
      email: 'user2@example.com',
      password: 'password123',
      confirmPassword: 'password123',
    });
  userToken2 = res2.body.token;
  userId2 = res2.body.user.id;
});

beforeEach(async () => {
  await db.query('DELETE FROM books');
});

afterAll(async () => {
  const uploadDir = path.join(__dirname, '../uploads');
  if (fs.existsSync(uploadDir)) {
    const files = fs.readdirSync(uploadDir);
    for (const file of files) {
      if (file !== '.gitkeep') {
        try { fs.unlinkSync(path.join(uploadDir, file)); } catch (e) {}
      }
    }
  }
  await db.query('DELETE FROM books');
  await db.query('DELETE FROM users');
  await db.pool.end();
});

describe('Book Management Module APIs', () => {
  const testBook = {
    title: 'Clean Code',
    author: 'Robert C. Martin',
    genre: 'Software Engineering',
    publication_year: 2008,
  };

  describe('POST /api/books (Add Book)', () => {
    it('should add a book successfully with valid details (no cover)', async () => {
      const res = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('message', 'Book added successfully');
      expect(res.body.book).toHaveProperty('id');
      expect(res.body.book.title).toBe(testBook.title);
      expect(res.body.book.author).toBe(testBook.author);
      expect(res.body.book.genre).toBe(testBook.genre);
      expect(res.body.book.publication_year).toBe(testBook.publication_year);
      expect(res.body.book.cover_image).toBeNull();
    });

    it('should add a book successfully with valid details and a cover image', async () => {
      const res = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .field('title', 'The Pragmatic Programmer')
        .field('author', 'Andrew Hunt')
        .field('genre', 'Software Engineering')
        .field('publication_year', 1999)
        .attach('cover', Buffer.from('fake-image-data'), 'cover.jpg');

      expect(res.status).toBe(201);
      expect(res.body.book).toHaveProperty('id');
      expect(res.body.book.cover_image).not.toBeNull();
      expect(res.body.book.cover_image).toMatch(/^\/uploads\//);

      const filePath = path.join(__dirname, '..', res.body.book.cover_image);
      expect(fs.existsSync(filePath)).toBe(true);
    });

    it('should reject creation when missing required fields', async () => {
      const res = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Incomplete Book',
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Title, author, genre, and publication year are required');
    });

    it('should reject creation with future publication year', async () => {
      const futureYear = new Date().getFullYear() + 1;
      const res = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          ...testBook,
          publication_year: futureYear,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid publication year');
    });

    it('should reject creation with year older than 1000', async () => {
      const res = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          ...testBook,
          publication_year: 999,
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid publication year');
    });
  });

  describe('GET /api/books (Get Books)', () => {
    it('should retrieve only the authenticated user\'s book list', async () => {
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);

      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken2}`)
        .send({
          title: 'Design Patterns',
          author: 'Gang of Four',
          genre: 'Software Engineering',
          publication_year: 1994,
        });

      const res1 = await request(app)
        .get('/api/books')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res1.status).toBe(200);
      expect(res1.body.books.length).toBe(1);
      expect(res1.body.books[0].title).toBe('Clean Code');

      const res2 = await request(app)
        .get('/api/books')
        .set('Authorization', `Bearer ${userToken2}`);

      expect(res2.status).toBe(200);
      expect(res2.body.books.length).toBe(1);
      expect(res2.body.books[0].title).toBe('Design Patterns');
    });
  });

  describe('GET /api/books/:id (Get Book Details)', () => {
    it('should get details of own book', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);
      const bookId = addRes.body.book.id;

      const res = await request(app)
        .get(`/api/books/${bookId}`)
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.book.title).toBe(testBook.title);
    });

    it('should return 403 when trying to access another user\'s book', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken2}`)
        .send(testBook);
      const bookId = addRes.body.book.id;

      const res = await request(app)
        .get(`/api/books/${bookId}`)
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('error', 'Access denied to this book');
    });

    it('should return 404 if book does not exist', async () => {
      const res = await request(app)
        .get('/api/books/999999')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('error', 'Book not found');
    });
  });

  describe('PUT /api/books/:id (Edit Book)', () => {
    it('should edit details of own book successfully', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send(testBook);
      const bookId = addRes.body.book.id;

      const res = await request(app)
        .put(`/api/books/${bookId}`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Clean Code (Updated)',
          publication_year: 2009,
        });

      expect(res.status).toBe(200);
      expect(res.body.book.title).toBe('Clean Code (Updated)');
      expect(res.body.book.publication_year).toBe(2009);
      expect(res.body.book.author).toBe(testBook.author);
    });

    it('should edit cover image and clean up old cover image file', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .field('title', 'Cover Edit Test')
        .field('author', 'Author')
        .field('genre', 'Genre')
        .field('publication_year', 2020)
        .attach('cover', Buffer.from('image-one'), 'one.jpg');

      const bookId = addRes.body.book.id;
      const firstCoverPath = path.join(__dirname, '..', addRes.body.book.cover_image);
      expect(fs.existsSync(firstCoverPath)).toBe(true);

      const editRes = await request(app)
        .put(`/api/books/${bookId}`)
        .set('Authorization', `Bearer ${userToken1}`)
        .attach('cover', Buffer.from('image-two'), 'two.jpg');

      expect(editRes.status).toBe(200);
      const secondCoverPath = path.join(__dirname, '..', editRes.body.book.cover_image);
      expect(fs.existsSync(secondCoverPath)).toBe(true);

      expect(fs.existsSync(firstCoverPath)).toBe(false);
    });

    it('should prevent editing another user\'s book', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken2}`)
        .send(testBook);
      const bookId = addRes.body.book.id;

      const res = await request(app)
        .put(`/api/books/${bookId}`)
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Hacked Title',
        });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('error', 'Access denied to this book');
    });
  });

  describe('DELETE /api/books/:id (Delete Book)', () => {
    it('should delete own book and clean up cover file', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .field('title', 'To Delete')
        .field('author', 'Author')
        .field('genre', 'Genre')
        .field('publication_year', 2020)
        .attach('cover', Buffer.from('delete-me'), 'del.jpg');

      const bookId = addRes.body.book.id;
      const coverPath = path.join(__dirname, '..', addRes.body.book.cover_image);
      expect(fs.existsSync(coverPath)).toBe(true);

      const res = await request(app)
        .delete(`/api/books/${bookId}`)
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message', 'Book deleted successfully');

      const dbCheck = await db.query('SELECT * FROM books WHERE id = $1', [bookId]);
      expect(dbCheck.rows.length).toBe(0);

      expect(fs.existsSync(coverPath)).toBe(false);
    });

    it('should prevent deleting another user\'s book', async () => {
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken2}`)
        .send(testBook);
      const bookId = addRes.body.book.id;

      const res = await request(app)
        .delete(`/api/books/${bookId}`)
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('error', 'Access denied to this book');
    });
  });
});
