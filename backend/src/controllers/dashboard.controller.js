const db = require('../db');
const { getGoalProgress } = require('./goal.controller');

exports.getDashboardStats = async (req, res) => {
  try {
    const userId = req.user.id;

    // 1. Fetch collection stats, total pages read, and average rating
    const collectionStatsResult = await db.query(
      `SELECT 
        COUNT(*) as total_books,
        COUNT(*) FILTER (WHERE shelf = 'Want To Read') as want_to_read,
        COUNT(*) FILTER (WHERE shelf = 'Currently Reading') as currently_reading,
        COUNT(*) FILTER (WHERE shelf = 'Finished Reading') as finished_reading,
        COALESCE(SUM(current_page), 0) as total_pages_read,
        COALESCE(AVG(rating) FILTER (WHERE rating IS NOT NULL), 0) as average_rating
       FROM books 
       WHERE user_id = $1`,
      [userId]
    );

    const rawStats = collectionStatsResult.rows[0];
    const totalBooks = parseInt(rawStats.total_books, 10);
    const totalBooksRead = parseInt(rawStats.finished_reading, 10);
    const currentlyReading = parseInt(rawStats.currently_reading, 10);
    const wantToRead = parseInt(rawStats.want_to_read, 10);
    const totalPagesRead = parseInt(rawStats.total_pages_read, 10);
    
    const completionRate = totalBooks > 0 ? parseFloat(((totalBooksRead / totalBooks) * 100).toFixed(2)) : 0;
    const averageRating = parseFloat(parseFloat(rawStats.average_rating).toFixed(2));

    // 2. Fetch genre distribution & favorite genre
    const genreResult = await db.query(
      `SELECT genre, COUNT(*) as count 
       FROM books 
       WHERE user_id = $1 
       GROUP BY genre 
       ORDER BY count DESC, genre ASC`,
      [userId]
    );

    const genreDistribution = genreResult.rows.map(row => ({
      genre: row.genre,
      count: parseInt(row.count, 10)
    }));

    const favoriteGenre = genreDistribution.length > 0 ? genreDistribution[0].genre : null;

    // 3. Fetch monthly and annual completion counts
    const monthlyAnnualResult = await db.query(
      `SELECT 
        COUNT(*) FILTER (WHERE completion_date >= DATE_TRUNC('month', CURRENT_DATE)) as month_count,
        COUNT(*) FILTER (WHERE completion_date >= DATE_TRUNC('year', CURRENT_DATE)) as year_count
       FROM books
       WHERE user_id = $1 AND shelf = 'Finished Reading' AND completion_date IS NOT NULL`,
      [userId]
    );

    const monthlyStats = monthlyAnnualResult.rows[0];
    const booksFinishedThisMonth = parseInt(monthlyStats.month_count, 10);
    const booksFinishedThisYear = parseInt(monthlyStats.year_count, 10);

    // 4. Fetch completion dates to calculate the streak
    const streakResult = await db.query(
      `SELECT DISTINCT completion_date 
       FROM books 
       WHERE user_id = $1 AND shelf = 'Finished Reading' AND completion_date IS NOT NULL 
       ORDER BY completion_date DESC`,
      [userId]
    );

    let readingStreak = 0;
    if (streakResult.rows.length > 0) {
      const dates = streakResult.rows.map(row => new Date(row.completion_date));

      const normalizeDate = (d) => {
        const copy = new Date(d);
        copy.setHours(0, 0, 0, 0);
        return copy;
      };

      const today = normalizeDate(new Date());
      const yesterday = normalizeDate(new Date());
      yesterday.setDate(yesterday.getDate() - 1);

      const firstCompletionDate = normalizeDate(dates[0]);

      if (firstCompletionDate.getTime() === today.getTime() || firstCompletionDate.getTime() === yesterday.getTime()) {
        readingStreak = 1;
        let currentExpectedDate = firstCompletionDate;

        for (let i = 1; i < dates.length; i++) {
          const nextDate = normalizeDate(dates[i]);
          const expectedDate = new Date(currentExpectedDate);
          expectedDate.setDate(expectedDate.getDate() - 1);

          if (nextDate.getTime() === expectedDate.getTime()) {
            readingStreak++;
            currentExpectedDate = nextDate;
          } else if (nextDate.getTime() > expectedDate.getTime()) {
            continue;
          } else {
            break;
          }
        }
      }
    }

    // 5. Fetch current year's reading goal
    const currentYear = new Date().getFullYear();
    const goalResult = await db.query(
      'SELECT * FROM goals WHERE user_id = $1 AND year = $2',
      [userId, currentYear]
    );

    let readingGoal = null;
    if (goalResult.rows.length > 0) {
      const goal = goalResult.rows[0];
      const details = await getGoalProgress(userId, goal.year, goal.target_books);
      readingGoal = {
        id: goal.id,
        year: goal.year,
        targetBooks: goal.target_books,
        completedBooks: details.completedBooks,
        progressPercentage: details.progressPercentage,
        status: details.status
      };
    }

    return res.status(200).json({
      collectionStats: {
        totalBooks,
        totalBooksRead,
        currentlyReading,
        wantToRead
      },
      readingStats: {
        totalPagesRead,
        completionRate,
        averageRating
      },
      genreAnalysis: {
        genreDistribution,
        favoriteGenre
      },
      readingInsights: {
        booksFinishedThisMonth,
        booksFinishedThisYear,
        readingStreak
      },
      readingGoal
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};
