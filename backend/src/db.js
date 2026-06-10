const { Pool, types } = require('pg');
// Parse DATE (type 1082) as string to prevent timezone offset shifts
types.setTypeParser(1082, (val) => val);
// Parse NUMERIC (type 1700) as float
types.setTypeParser(1700, (val) => parseFloat(val));

require('dotenv').config();

let pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

module.exports = {
  query: (text, params) => {
    if (pool.ended) {
      pool = new Pool({
        connectionString: process.env.DATABASE_URL,
      });
    }
    return pool.query(text, params);
  },
  get pool() {
    if (pool.ended) {
      pool = new Pool({
        connectionString: process.env.DATABASE_URL,
      });
    }
    return pool;
  },
  transaction: async (callback) => {
    if (pool.ended) {
      pool = new Pool({
        connectionString: process.env.DATABASE_URL,
      });
    }
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },
};
