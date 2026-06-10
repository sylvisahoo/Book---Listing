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
  await db.query('DELETE FROM books');
  await db.query('DELETE FROM users');
  await db.pool.end();
});

describe('Statistics Dashboard Module APIs', () => {
  describe('GET /api/dashboard/stats', () => {
    it('should return empty stats structure when user has no books', async () => {
      const res = await request(app)
        .get('/api/dashboard/stats')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.collectionStats).toEqual({
        totalBooks: 0,
        totalBooksRead: 0,
        currentlyReading: 0,
        wantToRead: 0
      });
      expect(res.body.readingStats).toEqual({
        totalPagesRead: 0,
        completionRate: 0,
        averageRating: 0
      });
      expect(res.body.genreAnalysis).toEqual({
        genreDistribution: [],
        favoriteGenre: null
      });
      expect(res.body.readingInsights).toEqual({
        booksFinishedThisMonth: 0,
        booksFinishedThisYear: 0,
        readingStreak: 0
      });
      expect(res.body.readingGoal).toBeNull();
    });

    it('should aggregate statistics, calculate averages/rates, genres and streaks correctly', async () => {
      const todayStr = new Date().toISOString().split('T')[0];
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Book 1',
          author: 'Author A',
          genre: 'Fantasy',
          publication_year: 2000,
          shelf: 'Finished Reading',
          current_page: 300,
          total_pages: 300,
          completion_date: todayStr,
          rating: 5
        });

      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Book 2',
          author: 'Author B',
          genre: 'Fantasy',
          publication_year: 2005,
          shelf: 'Finished Reading',
          current_page: 200,
          total_pages: 200,
          completion_date: yesterdayStr,
          rating: 4
        });

      const twoDaysAgo = new Date();
      twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
      const twoDaysAgoStr = twoDaysAgo.toISOString().split('T')[0];
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Book 3',
          author: 'Author C',
          genre: 'Biography',
          publication_year: 2010,
          shelf: 'Finished Reading',
          current_page: 150,
          total_pages: 150,
          completion_date: twoDaysAgoStr,
          rating: 3
        });

      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Book 4',
          author: 'Author D',
          genre: 'Science',
          publication_year: 2015,
          shelf: 'Currently Reading',
          current_page: 100,
          total_pages: 400
        });

      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Book 5',
          author: 'Author E',
          genre: 'Science',
          publication_year: 2020,
          shelf: 'Want To Read'
        });

      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken2}`)
        .send({
          title: 'User 2 Book',
          author: 'Author Z',
          genre: 'Fantasy',
          publication_year: 2012,
          shelf: 'Finished Reading',
          current_page: 500,
          total_pages: 500,
          completion_date: todayStr,
          rating: 5
        });

      const res = await request(app)
        .get('/api/dashboard/stats')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);

      expect(res.body.collectionStats).toEqual({
        totalBooks: 5,
        totalBooksRead: 3,
        currentlyReading: 1,
        wantToRead: 1
      });

      expect(res.body.readingStats).toEqual({
        totalPagesRead: 750,
        completionRate: 60,
        averageRating: 4
      });

      expect(res.body.genreAnalysis.genreDistribution).toEqual([
        { genre: 'Fantasy', count: 2 },
        { genre: 'Science', count: 2 },
        { genre: 'Biography', count: 1 }
      ]);
      expect(res.body.genreAnalysis.favoriteGenre).toBe('Fantasy');

      expect(res.body.readingInsights.booksFinishedThisMonth).toBe(3);
      expect(res.body.readingInsights.booksFinishedThisYear).toBe(3);
      expect(res.body.readingInsights.readingStreak).toBe(3);
    });

    it('should return 0 streak if last completion date was before yesterday', async () => {
      const longAgo = new Date();
      longAgo.setDate(longAgo.getDate() - 3);
      const longAgoStr = longAgo.toISOString().split('T')[0];

      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Old Book',
          author: 'Author',
          genre: 'Fiction',
          publication_year: 2000,
          shelf: 'Finished Reading',
          completion_date: longAgoStr,
          rating: 4
        });

      const res = await request(app)
        .get('/api/dashboard/stats')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.readingInsights.readingStreak).toBe(0);
    });

    it('should return current year\'s reading goal details in dashboard stats', async () => {
      const currentYear = new Date().getFullYear();
      await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          year: currentYear,
          target_books: 5
        });

      const todayStr = new Date().toISOString().split('T')[0];
      await request(app)
        .post('/api/books')
        .set('Authorization', `Bearer ${userToken1}`)
        .send({
          title: 'Goal Book 1',
          author: 'Author G1',
          genre: 'Science',
          publication_year: 2020,
          shelf: 'Finished Reading',
          completion_date: todayStr,
          rating: 4,
          current_page: 100,
          total_pages: 100
        });

      const res = await request(app)
        .get('/api/dashboard/stats')
        .set('Authorization', `Bearer ${userToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.readingGoal).not.toBeNull();
      expect(res.body.readingGoal).toEqual({
        id: expect.any(Number),
        year: currentYear,
        targetBooks: 5,
        completedBooks: 1,
        progressPercentage: 20,
        status: 'In Progress'
      });
    });
  });
});
