const request = require('supertest');
const fs = require('fs');
const path = require('path');
const app = require('../src/app');
const db = require('../src/db');
const { runBackup } = require('../scripts/backup');
const { runRestore } = require('../scripts/restore');

let userToken;
let userId;

beforeAll(async () => {
  await db.query('DELETE FROM goals');
  await db.query('DELETE FROM books');
  await db.query('DELETE FROM users');

  const res = await request(app)
    .post('/api/auth/register')
    .send({
      name: 'DB Test User',
      email: 'dbtest@example.com',
      password: 'password123',
      confirmPassword: 'password123',
    });
  userToken = res.body.token;
  userId = res.body.user.id;
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

describe('API & Database Management Module Tests', () => {
  
  describe('Pagination Support (KPI 6)', () => {
    it('should support page and limit pagination parameters', async () => {
      // 1. Insert 5 books
      for (let i = 1; i <= 5; i++) {
        await request(app)
          .post('/api/books')
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            title: `Book ${i}`,
            author: `Author ${i}`,
            genre: 'Genre',
            publication_year: 2020,
          });
      }

      // 2. Query Page 1 Limit 2
      const resPage1 = await request(app)
        .get('/api/books?page=1&limit=2')
        .set('Authorization', `Bearer ${userToken}`);

      expect(resPage1.status).toBe(200);
      expect(resPage1.body.books.length).toBe(2);
      expect(resPage1.body.pagination).toEqual({
        totalBooks: 5,
        page: 1,
        limit: 2,
        totalPages: 3
      });

      // 3. Query Page 2 Limit 2
      const resPage2 = await request(app)
        .get('/api/books?page=2&limit=2')
        .set('Authorization', `Bearer ${userToken}`);

      expect(resPage2.status).toBe(200);
      expect(resPage2.body.books.length).toBe(2);
      expect(resPage2.body.pagination).toEqual({
        totalBooks: 5,
        page: 2,
        limit: 2,
        totalPages: 3
      });

      // 4. Query Page 3 Limit 2
      const resPage3 = await request(app)
        .get('/api/books?page=3&limit=2')
        .set('Authorization', `Bearer ${userToken}`);

      expect(resPage3.status).toBe(200);
      expect(resPage3.body.books.length).toBe(1);
      expect(resPage3.body.pagination).toEqual({
        totalBooks: 5,
        page: 3,
        limit: 2,
        totalPages: 3
      });
    });

    it('should return 400 for invalid page or limit values', async () => {
      const res1 = await request(app)
        .get('/api/books?page=0&limit=2')
        .set('Authorization', `Bearer ${userToken}`);
      expect(res1.status).toBe(400);

      const res2 = await request(app)
        .get('/api/books?page=1&limit=-1')
        .set('Authorization', `Bearer ${userToken}`);
      expect(res2.status).toBe(400);
    });
  });

  describe('Database Integrity - Foreign Key Constraints (KPI 5)', () => {
    it('should reject book insertion with non-existent user_id', async () => {
      try {
        await db.query(
          'INSERT INTO books (user_id, title, author, genre, publication_year) VALUES ($1, $2, $3, $4, $5)',
          [999999, 'Invalid User Book', 'Author', 'Genre', 2000]
        );
        fail('Should have thrown foreign key constraint error');
      } catch (error) {
        expect(error.code).toBe('23503'); // Postgres foreign_key_violation code
      }
    });
  });

  describe('Concurrent Transaction Handling (KPI 8)', () => {
    it('should execute concurrent updates sequentially without corruption', async () => {
      // 1. Create a book to edit progress
      const addRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          title: 'Concurrency Test Book',
          author: 'Author',
          genre: 'Science',
          publication_year: 2020,
          shelf: 'Currently Reading',
        });
      const bookId = addRes.body.book.id;

      // 2. Perform concurrent progress update requests
      const promises = [10, 20, 30, 40, 50].map((page) => {
        return request(app)
          .patch(`/api/books/${bookId}/progress`)
          .set('Authorization', `Bearer ${userToken}`)
          .send({
            current_page: page,
            total_pages: 100,
          });
      });

      const responses = await Promise.all(promises);

      // Verify all completed successfully
      responses.forEach((res) => {
        expect(res.status).toBe(200);
        expect(res.body.message).toBe('Reading progress updated successfully');
      });

      // Verify the final state reflects one of the update values
      const checkRes = await request(app)
        .get(`/api/books/${bookId}`)
        .set('Authorization', `Bearer ${userToken}`);

      expect(checkRes.status).toBe(200);
      expect([10, 20, 30, 40, 50]).toContain(checkRes.body.book.current_page);
    });
  });

  describe('API Performance Optimization (KPI 4)', () => {
    it('should respond within the defined response time threshold (200ms)', async () => {
      const startTime = Date.now();
      
      const res = await request(app)
        .get('/api/books')
        .set('Authorization', `Bearer ${userToken}`);

      const duration = Date.now() - startTime;
      expect(res.status).toBe(200);
      expect(duration).toBeLessThan(200); // Assert response time is < 200ms
    });
  });

  describe('Database Backup & Recovery Process (KPI 7)', () => {
    it('should backup and restore database correctly', async () => {
      const backupFilePath = path.join(__dirname, '../backups/test-backup.dump');

      // 1. Insert a baseline book
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          title: 'Baseline Book',
          author: 'Author',
          genre: 'Genre',
          publication_year: 2020,
        });

      // 2. Perform a backup
      runBackup(backupFilePath);
      expect(fs.existsSync(backupFilePath)).toBe(true);

      // 3. Insert a new book after backup
      const tempBookRes = await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          title: 'Temporary Book Post-Backup',
          author: 'Author',
          genre: 'Genre',
          publication_year: 2020,
        });
      const tempBookId = tempBookRes.body.book.id;

      // Verify it exists in DB
      const checkPreRestore = await db.query('SELECT * FROM books WHERE id = $1', [tempBookId]);
      expect(checkPreRestore.rows.length).toBe(1);

      // 4. Perform a restore
      runRestore(backupFilePath);

      // Verify temporary book no longer exists (state reverted)
      const checkPostRestore = await db.query('SELECT * FROM books WHERE id = $1', [tempBookId]);
      expect(checkPostRestore.rows.length).toBe(0);

      // Verify baseline book still exists
      const checkBaseline = await db.query('SELECT * FROM books WHERE title = $1', ['Baseline Book']);
      expect(checkBaseline.rows.length).toBe(1);

      // Clean up temp backup file
      try {
        fs.unlinkSync(backupFilePath);
      } catch (e) {}
    });
  });
});
