#!/usr/bin/env node

/**
 * Seed Script — populates the database with dummy data so that
 * the app shows meaningful content on first launch.
 *
 * Usage:
 *   node scripts/seed.js
 *   npm run db:seed
 *
 * Login credentials for the demo user:
 *   Email:    demo@bookly.com
 *   Password: Demo@1234
 */

const bcrypt = require('bcryptjs');
const db = require('../src/db');

async function seed() {
  console.log('🌱 Seeding database …');

  // ─── 1. Create demo user ──────────────────────────────────────────────
  const passwordHash = await bcrypt.hash('Demo@1234', 10);

  const userResult = await db.query(
    `INSERT INTO users (name, email, password_hash)
     VALUES ($1, $2, $3)
     ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
     RETURNING id`,
    ['Demo User', 'demo@bookly.com', passwordHash],
  );

  const userId = userResult.rows[0].id;
  console.log(`✅ Demo user ready  (id=${userId})`);

  // ─── 2. Clear any old books & goals for this user ─────────────────────
  await db.query('DELETE FROM books WHERE user_id = $1', [userId]);
  await db.query('DELETE FROM goals WHERE user_id = $1', [userId]);
  console.log('🧹 Cleared previous data for demo user');

  // ─── 3. Insert books ─────────────────────────────────────────────────
  const books = [
    // ── Finished Reading (with ratings, reviews, completion dates) ──────
    {
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      genre: 'Fiction',
      publication_year: 1960,
      shelf: 'Finished Reading',
      current_page: 281,
      total_pages: 281,
      completion_date: '2026-01-15',
      rating: 5,
      review: 'A timeless classic that beautifully addresses racial injustice and moral growth through the eyes of a child. Scout Finch is one of the most memorable narrators in literature.',
    },
    {
      title: 'Atomic Habits',
      author: 'James Clear',
      genre: 'Self-Help',
      publication_year: 2018,
      shelf: 'Finished Reading',
      current_page: 320,
      total_pages: 320,
      completion_date: '2026-02-20',
      rating: 4,
      review: 'Practical and actionable advice on building good habits and breaking bad ones. The 1% improvement philosophy is life-changing.',
    },
    {
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      genre: 'Fiction',
      publication_year: 1925,
      shelf: 'Finished Reading',
      current_page: 180,
      total_pages: 180,
      completion_date: '2025-11-05',
      rating: 4,
      review: 'A dazzling portrayal of the American Dream and its discontents. Fitzgerald\'s prose is gorgeous, and the tragedy of Gatsby still resonates.',
    },
    {
      title: 'Sapiens: A Brief History of Humankind',
      author: 'Yuval Noah Harari',
      genre: 'Non-Fiction',
      publication_year: 2011,
      shelf: 'Finished Reading',
      current_page: 443,
      total_pages: 443,
      completion_date: '2025-08-12',
      rating: 5,
      review: 'An extraordinary sweep through 70,000 years of human history. Makes you rethink everything you thought you knew about civilisation.',
    },
    {
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      genre: 'Fiction',
      publication_year: 1988,
      shelf: 'Finished Reading',
      current_page: 197,
      total_pages: 197,
      completion_date: '2025-06-30',
      rating: 3,
      review: 'A simple but inspiring fable about following your dreams. Some readers may find it repetitive, but its core message is uplifting.',
    },

    // ── Currently Reading (with partial progress) ──────────────────────
    {
      title: 'Dune',
      author: 'Frank Herbert',
      genre: 'Science Fiction',
      publication_year: 1965,
      shelf: 'Currently Reading',
      current_page: 287,
      total_pages: 688,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'Thinking, Fast and Slow',
      author: 'Daniel Kahneman',
      genre: 'Psychology',
      publication_year: 2011,
      shelf: 'Currently Reading',
      current_page: 112,
      total_pages: 499,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'The Midnight Library',
      author: 'Matt Haig',
      genre: 'Fiction',
      publication_year: 2020,
      shelf: 'Currently Reading',
      current_page: 45,
      total_pages: 288,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'Clean Code',
      author: 'Robert C. Martin',
      genre: 'Technology',
      publication_year: 2008,
      shelf: 'Currently Reading',
      current_page: 198,
      total_pages: 464,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'The Name of the Wind',
      author: 'Patrick Rothfuss',
      genre: 'Fantasy',
      publication_year: 2007,
      shelf: 'Currently Reading',
      current_page: 310,
      total_pages: 662,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'Designing Data-Intensive Applications',
      author: 'Martin Kleppmann',
      genre: 'Technology',
      publication_year: 2017,
      shelf: 'Currently Reading',
      current_page: 78,
      total_pages: 616,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'The Power of Now',
      author: 'Eckhart Tolle',
      genre: 'Self-Help',
      publication_year: 1997,
      shelf: 'Currently Reading',
      current_page: 140,
      total_pages: 236,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'A Brief History of Time',
      author: 'Stephen Hawking',
      genre: 'Science',
      publication_year: 1988,
      shelf: 'Currently Reading',
      current_page: 55,
      total_pages: 212,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'The Lean Startup',
      author: 'Eric Ries',
      genre: 'Business',
      publication_year: 2011,
      shelf: 'Currently Reading',
      current_page: 180,
      total_pages: 336,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'Meditations',
      author: 'Marcus Aurelius',
      genre: 'Philosophy',
      publication_year: 180,
      shelf: 'Currently Reading',
      current_page: 62,
      total_pages: 254,
      completion_date: null,
      rating: null,
      review: null,
    },

    // ── Want To Read ───────────────────────────────────────────────────
    {
      title: '1984',
      author: 'George Orwell',
      genre: 'Dystopian',
      publication_year: 1949,
      shelf: 'Want To Read',
      current_page: 0,
      total_pages: 328,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'Educated',
      author: 'Tara Westover',
      genre: 'Memoir',
      publication_year: 2018,
      shelf: 'Want To Read',
      current_page: 0,
      total_pages: 334,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'Project Hail Mary',
      author: 'Andy Weir',
      genre: 'Science Fiction',
      publication_year: 2021,
      shelf: 'Want To Read',
      current_page: 0,
      total_pages: 476,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'The Psychology of Money',
      author: 'Morgan Housel',
      genre: 'Finance',
      publication_year: 2020,
      shelf: 'Want To Read',
      current_page: 0,
      total_pages: 256,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'Becoming',
      author: 'Michelle Obama',
      genre: 'Memoir',
      publication_year: 2018,
      shelf: 'Want To Read',
      current_page: 0,
      total_pages: 448,
      completion_date: null,
      rating: null,
      review: null,
    },
    {
      title: 'The Pragmatic Programmer',
      author: 'David Thomas & Andrew Hunt',
      genre: 'Technology',
      publication_year: 2019,
      shelf: 'Want To Read',
      current_page: 0,
      total_pages: 352,
      completion_date: null,
      rating: null,
      review: null,
    },
  ];

  for (const b of books) {
    await db.query(
      `INSERT INTO books
         (user_id, title, author, genre, publication_year,
          shelf, current_page, total_pages,
          completion_date, rating, review)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
      [
        userId,
        b.title,
        b.author,
        b.genre,
        b.publication_year,
        b.shelf,
        b.current_page,
        b.total_pages,
        b.completion_date,
        b.rating,
        b.review,
      ],
    );
  }
  console.log(`📚 Inserted ${books.length} books`);

  // ─── 4. Insert reading goals ──────────────────────────────────────────
  const goals = [
    { year: 2025, target_books: 12 },
    { year: 2026, target_books: 20 },
  ];

  for (const g of goals) {
    await db.query(
      `INSERT INTO goals (user_id, year, target_books)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, year) DO UPDATE SET target_books = EXCLUDED.target_books`,
      [userId, g.year, g.target_books],
    );
  }
  console.log(`🎯 Inserted ${goals.length} reading goals`);

  // ─── Done ─────────────────────────────────────────────────────────────
  console.log('\n✨ Seed complete!');
  console.log('   Email:    demo@bookly.com');
  console.log('   Password: Demo@1234\n');

  await db.pool.end();
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});
