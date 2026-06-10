const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bookController = require('../controllers/book.controller');
const authMiddleware = require('../middleware/auth');

// Ensure uploads folder exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure Multer storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

// File filter to accept only images
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif/;
  const mimetype = allowedTypes.test(file.mimetype);
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());

  if (mimetype && extname) {
    return cb(null, true);
  }
  cb(new Error('Only image files are allowed!'));
};

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter
});

// Apply auth middleware to all book routes
router.use(authMiddleware);

// Define routes
router.post('/', upload.single('cover'), bookController.addBook);
router.get('/', bookController.getBooks);
router.get('/shelves/stats', bookController.getShelfStats);
router.get('/:id', bookController.getBookById);
router.put('/:id', upload.single('cover'), bookController.editBook);
router.patch('/:id/shelf', bookController.updateBookShelf);
router.patch('/:id/progress', bookController.updateProgress);
router.post('/:id/review', bookController.addReview);
router.delete('/:id', bookController.deleteBook);

module.exports = router;
