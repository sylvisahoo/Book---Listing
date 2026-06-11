const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const authRoutes = require('./routes/auth.routes');
const bookRoutes = require('./routes/book.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const goalRoutes = require('./routes/goal.routes');

const app = express();

app.use(cors());
app.use(express.json());

// Logging middleware
app.use((req, res, next) => {
  console.log(`\n--- [${new Date().toISOString()}] ${req.method} ${req.url} ---`);
  console.log('Headers:', JSON.stringify(req.headers));
  console.log('Body:', JSON.stringify(req.body));
  
  const originalSend = res.send;
  res.send = function (body) {
    console.log(`--- Response Status: ${res.statusCode} ---`);
    console.log('Response Body:', body);
    return originalSend.apply(res, arguments);
  };
  
  next();
});

// Serve uploads folder statically
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/books', bookRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/goals', goalRoutes);

// Export app for testing
module.exports = app;

if (process.env.NODE_ENV !== 'test') {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT);
}
