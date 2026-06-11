const path = require('path');
const fs = require('fs');
const db = require('../db');
const { mapDatabaseError } = require('../utils/errorHandler');

exports.addBook = async (req, res) => {
  try {
    const { title, author, genre, publication_year, shelf, current_page, total_pages, completion_date, rating, review } = req.body;
    const userId = req.user.id;

    if (!title || !author || !genre || !publication_year) {
      if (req.file) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(400).json({ error: 'Title, author, genre, and publication year are required' });
    }

    const pubYear = parseInt(publication_year, 10);
    const currentYear = new Date().getFullYear();
    if (isNaN(pubYear) || pubYear < 1000 || pubYear > currentYear) {
      if (req.file) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(400).json({ error: 'Invalid publication year' });
    }

    let shelfValue = 'Want To Read';
    if (shelf) {
      const validShelves = ['Want To Read', 'Currently Reading', 'Finished Reading'];
      if (!validShelves.includes(shelf)) {
        if (req.file) {
          fs.unlinkSync(req.file.path);
        }
        return res.status(400).json({ error: 'Invalid shelf value' });
      }
      shelfValue = shelf;
    }

    let currPage = 0;
    if (current_page !== undefined) {
      currPage = parseInt(current_page, 10);
      if (isNaN(currPage) || currPage < 0) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid current page number' });
      }
    }

    let totPages = 0;
    if (total_pages !== undefined) {
      totPages = parseInt(total_pages, 10);
      if (isNaN(totPages) || totPages < 0) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid total pages number' });
      }
    }

    if (currPage > totPages) {
      if (req.file) fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: 'Current page cannot exceed total pages' });
    }

    let ratingVal = null;
    if (rating !== undefined && rating !== null && rating !== '') {
      ratingVal = parseInt(rating, 10);
      if (isNaN(ratingVal) || ratingVal < 1 || ratingVal > 5) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid rating. Must be between 1 and 5' });
      }
    }

    let compDate = null;
    if (completion_date) {
      const parsedDate = new Date(completion_date);
      if (isNaN(parsedDate.getTime()) || parsedDate > new Date()) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid completion date' });
      }
      compDate = completion_date;
    }

    let revVal = null;
    if (review) {
      if (review.length > 2000) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Review exceeds maximum length of 2000 characters' });
      }
      revVal = review;
    }

    let coverImage = null;
    if (req.file) {
      coverImage = `/uploads/${req.file.filename}`;
    }

    const result = await db.query(
      'INSERT INTO books (user_id, title, author, genre, publication_year, cover_image, shelf, current_page, total_pages, completion_date, rating, review) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *',
      [userId, title, author, genre, pubYear, coverImage, shelfValue, currPage, totPages, compDate, ratingVal, revVal]
    );

    return res.status(201).json({
      message: 'Book added successfully',
      book: result.rows[0]
    });
  } catch (error) {
    console.error('Error in addBook:', error);
    if (req.file) {
      try { fs.unlinkSync(req.file.path); } catch (e) {}
    }
    const mapped = mapDatabaseError(error, 'Book creation failed. Please try again.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.getBooks = async (req, res) => {
  try {
    const userId = req.user.id;
    const { search, genre, rating, shelf, sort, page, limit } = req.query;

    let filterQuery = 'FROM books WHERE user_id = $1';
    const queryParams = [userId];

    if (search) {
      queryParams.push(`%${search}%`);
      filterQuery += ` AND (title ILIKE $${queryParams.length} OR author ILIKE $${queryParams.length})`;
    }

    if (genre) {
      queryParams.push(genre);
      filterQuery += ` AND genre = $${queryParams.length}`;
    }

    if (rating !== undefined && rating !== '') {
      const ratingVal = parseInt(rating, 10);
      if (!isNaN(ratingVal)) {
        queryParams.push(ratingVal);
        filterQuery += ` AND rating = $${queryParams.length}`;
      }
    }

    if (shelf) {
      queryParams.push(shelf);
      filterQuery += ` AND shelf = $${queryParams.length}`;
    }

    // Get total count
    const countResult = await db.query(`SELECT COUNT(*) ${filterQuery}`, queryParams);
    const totalBooks = parseInt(countResult.rows[0].count, 10);

    // Apply sorting
    let orderBy = ' ORDER BY id DESC';
    if (sort) {
      switch (sort) {
        case 'title_asc':
          orderBy = ' ORDER BY title ASC, id DESC';
          break;
        case 'title_desc':
          orderBy = ' ORDER BY title DESC, id DESC';
          break;
        case 'author_asc':
          orderBy = ' ORDER BY author ASC, id DESC';
          break;
        case 'newest':
          orderBy = ' ORDER BY id DESC';
          break;
        case 'oldest':
          orderBy = ' ORDER BY id ASC';
          break;
        case 'highest_rated':
          orderBy = ' ORDER BY rating DESC NULLS LAST, id DESC';
          break;
      }
    }

    // Default to page 1, limit 10
    const pageVal = page ? parseInt(page, 10) : 1;
    const limitVal = limit ? parseInt(limit, 10) : 10;

    if (isNaN(pageVal) || pageVal <= 0) {
      return res.status(400).json({ error: 'Page must be a positive integer' });
    }
    if (isNaN(limitVal) || limitVal <= 0) {
      return res.status(400).json({ error: 'Limit must be a positive integer' });
    }

    const offsetVal = (pageVal - 1) * limitVal;

    const selectParams = [...queryParams, limitVal, offsetVal];
    const selectQuery = `SELECT * ${filterQuery}${orderBy} LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;

    const result = await db.query(selectQuery, selectParams);
    const totalPages = Math.ceil(totalBooks / limitVal);

    return res.status(200).json({
      books: result.rows,
      pagination: {
        totalBooks,
        page: pageVal,
        limit: limitVal,
        totalPages
      }
    });
  } catch (error) {
    console.error('Error in getBooks:', error);
    const mapped = mapDatabaseError(error, 'Failed to retrieve books.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.getBookById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await db.query('SELECT * FROM books WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Book not found' });
    }

    const book = result.rows[0];
    if (book.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied to this book' });
    }

    return res.status(200).json({ book });
  } catch (error) {
    console.error('Error in getBookById:', error);
    const mapped = mapDatabaseError(error, 'Failed to retrieve book details.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.editBook = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { title, author, genre, publication_year, shelf, current_page, total_pages, completion_date, rating, review } = req.body;

    const bookResult = await db.query('SELECT * FROM books WHERE id = $1', [id]);
    if (bookResult.rows.length === 0) {
      if (req.file) fs.unlinkSync(req.file.path);
      return res.status(404).json({ error: 'Book not found' });
    }

    const book = bookResult.rows[0];
    if (book.user_id !== userId) {
      if (req.file) fs.unlinkSync(req.file.path);
      return res.status(403).json({ error: 'Access denied to this book' });
    }

    const updatedTitle = title !== undefined ? title : book.title;
    const updatedAuthor = author !== undefined ? author : book.author;
    const updatedGenre = genre !== undefined ? genre : book.genre;
    
    let updatedPubYear = book.publication_year;
    if (publication_year !== undefined) {
      const pubYear = parseInt(publication_year, 10);
      const currentYear = new Date().getFullYear();
      if (isNaN(pubYear) || pubYear < 1000 || pubYear > currentYear) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid publication year' });
      }
      updatedPubYear = pubYear;
    }

    let updatedShelf = book.shelf;
    if (shelf !== undefined) {
      const validShelves = ['Want To Read', 'Currently Reading', 'Finished Reading'];
      if (!validShelves.includes(shelf)) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid shelf value' });
      }
      updatedShelf = shelf;
    }

    let updatedCurrentPage = book.current_page;
    if (current_page !== undefined) {
      const currPage = parseInt(current_page, 10);
      if (isNaN(currPage) || currPage < 0) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid current page number' });
      }
      updatedCurrentPage = currPage;
    }

    let updatedTotalPages = book.total_pages;
    if (total_pages !== undefined) {
      const totPages = parseInt(total_pages, 10);
      if (isNaN(totPages) || totPages < 0) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid total pages number' });
      }
      updatedTotalPages = totPages;
    }

    if (updatedCurrentPage > updatedTotalPages) {
      if (req.file) fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: 'Current page cannot exceed total pages' });
    }

    let updatedRating = book.rating;
    if (rating !== undefined) {
      if (rating === null || rating === '') {
        updatedRating = null;
      } else {
        const ratingVal = parseInt(rating, 10);
        if (isNaN(ratingVal) || ratingVal < 1 || ratingVal > 5) {
          if (req.file) fs.unlinkSync(req.file.path);
          return res.status(400).json({ error: 'Invalid rating. Must be between 1 and 5' });
        }
        updatedRating = ratingVal;
      }
    }

    let updatedCompDate = book.completion_date;
    if (completion_date !== undefined) {
      if (completion_date === null || completion_date === '') {
        updatedCompDate = null;
      } else {
        const parsedDate = new Date(completion_date);
        if (isNaN(parsedDate.getTime()) || parsedDate > new Date()) {
          if (req.file) fs.unlinkSync(req.file.path);
          return res.status(400).json({ error: 'Invalid completion date' });
        }
        updatedCompDate = completion_date;
      }
    }

    let updatedReview = book.review;
    if (review !== undefined) {
      if (review === null || review === '') {
        updatedReview = null;
      } else {
        if (review.length > 2000) {
          if (req.file) fs.unlinkSync(req.file.path);
          return res.status(400).json({ error: 'Review exceeds maximum length of 2000 characters' });
        }
        updatedReview = review;
      }
    }

    let updatedCoverImage = book.cover_image;
    if (req.file) {
      updatedCoverImage = `/uploads/${req.file.filename}`;
      if (book.cover_image) {
        const oldImagePath = path.join(__dirname, '../..', book.cover_image);
        if (fs.existsSync(oldImagePath)) {
          try { fs.unlinkSync(oldImagePath); } catch (e) {}
        }
      }
    }

    const result = await db.query(
      'UPDATE books SET title = $1, author = $2, genre = $3, publication_year = $4, cover_image = $5, shelf = $6, current_page = $7, total_pages = $8, completion_date = $9, rating = $10, review = $11 WHERE id = $12 RETURNING *',
      [updatedTitle, updatedAuthor, updatedGenre, updatedPubYear, updatedCoverImage, updatedShelf, updatedCurrentPage, updatedTotalPages, updatedCompDate, updatedRating, updatedReview, id]
    );

    return res.status(200).json({
      message: 'Book updated successfully',
      book: result.rows[0]
    });
  } catch (error) {
    console.error('Error in editBook:', error);
    if (req.file) {
      try { fs.unlinkSync(req.file.path); } catch (e) {}
    }
    const mapped = mapDatabaseError(error, 'Failed to update book.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.deleteBook = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const bookResult = await db.query('SELECT * FROM books WHERE id = $1', [id]);
    if (bookResult.rows.length === 0) {
      return res.status(404).json({ error: 'Book not found' });
    }

    const book = bookResult.rows[0];
    if (book.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied to this book' });
    }

    if (book.cover_image) {
      const imagePath = path.join(__dirname, '../..', book.cover_image);
      if (fs.existsSync(imagePath)) {
        try { fs.unlinkSync(imagePath); } catch (e) {}
      }
    }

    await db.query('DELETE FROM books WHERE id = $1', [id]);

    return res.status(200).json({ message: 'Book deleted successfully' });
  } catch (error) {
    console.error('Error in deleteBook:', error);
    const mapped = mapDatabaseError(error, 'Failed to delete book.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.updateBookShelf = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { shelf } = req.body;

    if (!shelf) {
      return res.status(400).json({ error: 'Shelf status is required' });
    }

    const validShelves = ['Want To Read', 'Currently Reading', 'Finished Reading'];
    if (!validShelves.includes(shelf)) {
      return res.status(400).json({ error: 'Invalid shelf value' });
    }

    const bookResult = await db.query('SELECT * FROM books WHERE id = $1', [id]);
    if (bookResult.rows.length === 0) {
      return res.status(404).json({ error: 'Book not found' });
    }

    const book = bookResult.rows[0];
    if (book.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied to this book' });
    }

    const result = await db.query(
      'UPDATE books SET shelf = $1 WHERE id = $2 RETURNING *',
      [shelf, id]
    );

    return res.status(200).json({
      message: 'Shelf updated successfully',
      book: result.rows[0]
    });
  } catch (error) {
    console.error('Error in updateBookShelf:', error);
    const mapped = mapDatabaseError(error, 'Failed to update book shelf.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.getShelfStats = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await db.query(
      `SELECT 
        COUNT(*) FILTER (WHERE shelf = 'Want To Read') as "wantToRead",
        COUNT(*) FILTER (WHERE shelf = 'Currently Reading') as "currentlyReading",
        COUNT(*) FILTER (WHERE shelf = 'Finished Reading') as "finishedReading"
       FROM books WHERE user_id = $1`,
      [userId]
    );

    const stats = result.rows[0];

    return res.status(200).json({
      wantToRead: parseInt(stats.wantToRead, 10),
      currentlyReading: parseInt(stats.currentlyReading, 10),
      finishedReading: parseInt(stats.finishedReading, 10)
    });
  } catch (error) {
    console.error('Error in getShelfStats:', error);
    const mapped = mapDatabaseError(error, 'Failed to retrieve shelf statistics.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.updateProgress = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { current_page, total_pages } = req.body;

    if (current_page === undefined || total_pages === undefined) {
      return res.status(400).json({ error: 'Current page and total pages are required' });
    }

    const currPage = parseInt(current_page, 10);
    const totPages = parseInt(total_pages, 10);

    if (isNaN(currPage) || currPage < 0) {
      return res.status(400).json({ error: 'Invalid current page number' });
    }
    if (isNaN(totPages) || totPages < 0) {
      return res.status(400).json({ error: 'Invalid total pages number' });
    }
    if (currPage > totPages) {
      return res.status(400).json({ error: 'Current page cannot exceed total pages' });
    }

    const resultData = await db.transaction(async (client) => {
      const bookResult = await client.query('SELECT * FROM books WHERE id = $1 FOR UPDATE', [id]);
      if (bookResult.rows.length === 0) {
        throw { status: 404, error: 'Book not found' };
      }

      const book = bookResult.rows[0];
      if (book.user_id !== userId) {
        throw { status: 403, error: 'Access denied to this book' };
      }

      if (book.shelf !== 'Currently Reading') {
        throw { status: 400, error: 'Progress tracking is only available for books currently being read' };
      }

      const updateResult = await client.query(
        'UPDATE books SET current_page = $1, total_pages = $2 WHERE id = $3 RETURNING *',
        [currPage, totPages, id]
      );
      return updateResult.rows[0];
    });

    const progress_percentage = totPages > 0 ? parseFloat(((currPage / totPages) * 100).toFixed(2)) : 0;

    return res.status(200).json({
      message: 'Reading progress updated successfully',
      book: resultData,
      progress_percentage
    });
  } catch (error) {
    console.error('Error in updateProgress:', error);
    if (error && error.status) {
      return res.status(error.status).json({ error: error.error });
    }
    const mapped = mapDatabaseError(error, 'Failed to update reading progress.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};

exports.addReview = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { completion_date, rating, review } = req.body;

    if (!completion_date || rating === undefined || rating === null) {
      return res.status(400).json({ error: 'Completion date and rating are required' });
    }

    const ratingVal = parseInt(rating, 10);
    if (isNaN(ratingVal) || ratingVal < 1 || ratingVal > 5) {
      return res.status(400).json({ error: 'Invalid rating. Must be between 1 and 5' });
    }

    const parsedDate = new Date(completion_date);
    if (isNaN(parsedDate.getTime()) || parsedDate > new Date()) {
      return res.status(400).json({ error: 'Invalid completion date' });
    }

    if (review && review.length > 2000) {
      return res.status(400).json({ error: 'Review exceeds maximum length of 2000 characters' });
    }

    const resultData = await db.transaction(async (client) => {
      const bookResult = await client.query('SELECT * FROM books WHERE id = $1 FOR UPDATE', [id]);
      if (bookResult.rows.length === 0) {
        throw { status: 404, error: 'Book not found' };
      }

      const book = bookResult.rows[0];
      if (book.user_id !== userId) {
        throw { status: 403, error: 'Access denied to this book' };
      }

      const updateResult = await client.query(
        `UPDATE books 
         SET shelf = 'Finished Reading', completion_date = $1, rating = $2, review = $3 
         WHERE id = $4 RETURNING *`,
        [completion_date, ratingVal, review || null, id]
      );
      return updateResult.rows[0];
    });

    return res.status(200).json({
      message: 'Review submitted successfully',
      book: resultData
    });
  } catch (error) {
    console.error('Error in addReview:', error);
    if (error && error.status) {
      return res.status(error.status).json({ error: error.error });
    }
    const mapped = mapDatabaseError(error, 'Failed to submit review.');
    return res.status(mapped.status).json({ error: mapped.error });
  }
};
