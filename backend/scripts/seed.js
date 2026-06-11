#!/usr/bin/env node

/**
 * Seed Script — populates the database with default user books and goals.
 *
 * Usage:
 *   npm run db:seed
 */

const bcrypt = require('bcryptjs');
const db = require('../src/db');
const { seedUserBooks } = require('../src/utils/userSeeder');

async function seed() {
  console.log('🌱 Seeding database …');

  const passwordHash = await bcrypt.hash('Demo@1234', 10);

  const userResult = await db.query(
    `INSERT INTO users (name, email, password_hash)
     VALUES ($1, $2, $3)
     ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
     RETURNING id`,
    ['Demo User', 'demo@bookly.com', passwordHash]
  );

  const userId = userResult.rows[0].id;
  console.log(`✅ Demo user ready (id=${userId})`);

  // Clear previous records for this user
  await db.query('DELETE FROM books WHERE user_id = $1', [userId]);
  await db.query('DELETE FROM goals WHERE user_id = $1', [userId]);
  console.log('🧹 Cleared previous data for demo user');

  // Seed books
  const count = await seedUserBooks(userId);
  console.log(`📚 Seeded ${count} books for demo user`);

  // Insert reading goals
  const goals = [
    { year: 2025, target_books: 12 },
    { year: 2026, target_books: 20 }
  ];

  for (const g of goals) {
    await db.query(
      `INSERT INTO goals (user_id, year, target_books)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, year) DO UPDATE SET target_books = EXCLUDED.target_books`,
      [userId, g.year, g.target_books]
    );
  }
  console.log(`🎯 Inserted ${goals.length} reading goals`);

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
