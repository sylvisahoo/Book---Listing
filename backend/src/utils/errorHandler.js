/**
 * Maps PostgreSQL and database connection errors to user-friendly messages and status codes.
 */
function mapDatabaseError(error, defaultMessage = 'An unexpected database error occurred.') {
  console.error('Mapped Database Error:', error);

  // Connection-related errors
  if (
    error.code === 'ECONNREFUSED' || 
    error.code === '57P01' || 
    error.code === '08001' || 
    error.code === '08003' || 
    error.code === '08004' || 
    error.code === '08006' || 
    error.code === '08P01'
  ) {
    return {
      status: 503,
      error: 'Database connection failed. Please ensure the database server is running and try again.'
    };
  }

  // Unique constraint violation (e.g. duplicate goal for same user + year)
  if (error.code === '23505') {
    return {
      status: 400,
      error: 'Duplicate entry: Record already exists.'
    };
  }

  // Foreign key constraint violation (e.g. referencing a user that doesn't exist)
  if (error.code === '23503') {
    return {
      status: 400,
      error: 'User account not found. Please sign in again.'
    };
  }

  // Check constraint violation (e.g. rating out of bounds or negative page progress)
  if (error.code === '23514') {
    return {
      status: 400,
      error: 'Validation failed: Input violates system limits and constraints.'
    };
  }

  // General fallback
  return {
    status: 500,
    error: defaultMessage
  };
}

module.exports = { mapDatabaseError };
