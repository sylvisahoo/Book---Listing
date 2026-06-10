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

  await request(app)
    .post('/api/books')
    .set('Authorization', `Bearer ${userToken1}`)
    .send({
      title: 'Clean Code',
      author: 'Robert C. Martin',
      genre: 'Software Engineering',
      publication_year: 2008,
      shelf: 'Finished Reading',
      rating: 5,
      current_page: 460,
      total_pages: 460,
    });

  await request(app)
    .post('/api/books')
    .set('Authorization', `Bearer ${userToken1}`)
    .send({
      title: 'Design Patterns',
      author: 'Erich Gamma',
      genre: 'Computer Science',
      publication_year: 1994,
      shelf: 'Want To Read',
      rating: 4,
    });

  await request(app)
    .post('/api/books')
    .set('Authorization', `Bearer ${userToken1}`)
    .send({
      title: 'Introduction to Algorithms',
      author: 'Thomas H. Cormen',
      genre: 'Computer Science',
      publication_year: 2009,
      shelf: 'Currently Reading',
      current_page: 200,
      total_pages: 1200,
    });

  await request(app)
    .post('/api/books')
    .set('Authorization', `Bearer ${userToken1}`)
    .send({
      title: 'Code Complete',
      author: 'Steve McConnell',
      genre: 'Software Engineering',
      publication_year: 2004,
      shelf: 'Finished Reading',
      rating: 5,
    });

  await request(app)
    .post('/api/books')
    .set('Authorization', `Bearer ${userToken2}`)
    .send({
      title: 'Hacking Beauty',
      author: 'Robert C. Martin',
      genre: 'Fiction',
      publication_year: 2015,
      shelf: 'Currently Reading',
    });
});

afterAll(async () => {
  await db.query('DELETE FROM books');
  await db.query('DELETE FROM users');
  await db.pool.end();
});

describe('Search & Filters Module APIs', () => {
  describe('GET /api/books (Search)', () => {
    it('should search partially and case-insensitively by title', async () => {
      const res = await request(app)
        .get('/api/books?search=code')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.books.length).toBe(2);
      const titles = res.body.books.map(b => b.title);
      expect(titles).toContain('Clean Code');
      expect(titles).toContain('Code Complete');
    });

    it('should search partially and case-insensitively by author', async () => {
      const res = await request(app)
        .get('/api/books?search=martin')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.books.length).toBe(1);
      expect(res.body.books[0].title).toBe('Clean Code');
    });
  });

  describe('GET /api/books (Filters)', () => {
    it('should filter books by genre', async () => {
      const res = await request(app)
        .get('/api/books?genre=Computer Science')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.books.length).toBe(2);
      const titles = res.body.books.map(b => b.title);
      expect(titles).toContain('Design Patterns');
      expect(titles).toContain('Introduction to Algorithms');
    });

    it('should filter books by rating', async () => {
      const res = await request(app)
        .get('/api/books?rating=5')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.books.length).toBe(2);
      const titles = res.body.books.map(b => b.title);
      expect(titles).toContain('Clean Code');
      expect(titles).toContain('Code Complete');
    });

    it('should filter books by reading status (shelf)', async () => {
      const res = await request(app)
        .get('/api/books?shelf=Finished Reading')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.books.length).toBe(2);
      const shelves = res.body.books.map(b => b.shelf);
      expect(shelves.every(s => s === 'Finished Reading')).toBe(true);
    });

    it('should return empty list when no book matches filtered criteria', async () => {
      const res = await request(app)
        .get('/api/books?genre=Nonexistent')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.books.length).toBe(0);
    });
  });

  describe('GET /api/books (Sorting)', () => {
    it('should sort books by Title A-Z', async () => {
      const res = await request(app)
        .get('/api/books?sort=title_asc')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      const titles = res.body.books.map(b => b.title);
      expect(titles).toEqual([
        'Clean Code',
        'Code Complete',
        'Design Patterns',
        'Introduction to Algorithms'
      ]);
    });

    it('should sort books by Title Z-A', async () => {
      const res = await request(app)
        .get('/api/books?sort=title_desc')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      const titles = res.body.books.map(b => b.title);
      expect(titles).toEqual([
        'Introduction to Algorithms',
        'Design Patterns',
        'Code Complete',
        'Clean Code'
      ]);
    });

    it('should sort books by Oldest first', async () => {
      const res = await request(app)
        .get('/api/books?sort=oldest')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      const titles = res.body.books.map(b => b.title);
      expect(titles).toEqual([
        'Clean Code',
        'Design Patterns',
        'Introduction to Algorithms',
        'Code Complete'
      ]);
    });

    it('should sort books by Highest Rated', async () => {
      const res = await request(app)
        .get('/api/books?sort=highest_rated')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      const ratings = res.body.books.map(b => b.rating);
      expect(ratings[0]).toBe(5);
      expect(ratings[1]).toBe(5);
      expect(ratings[2]).toBe(4);
      expect(ratings[3]).toBeNull();
    });
  });

  describe('GET /api/books (Combined Search, Filters & Sorting)', () => {
    it('should combine search, shelf filter, and title sorting', async () => {
      const res = await request(app)
        .get('/api/books?search=code&shelf=Finished Reading&sort=title_asc')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.books.length).toBe(2);
      const titles = res.body.books.map(b => b.title);
      expect(titles).toEqual(['Clean Code', 'Code Complete']);
    });
  });

  describe('GET /api/books (Security & User Isolation)', () => {
    it('should not return books of other users when performing search and retrieve', async () => {
      const res = await request(app)
        .get('/api/books?search=martin')
        .set('Authorization', `Bearer ${userToken2}`);

      expect(res.status).toBe(200);
      expect(res.body.books.length).toBe(1);
      expect(res.body.books[0].title).toBe('Hacking Beauty');
    });
  });
});
