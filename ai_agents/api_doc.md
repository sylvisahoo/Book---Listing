# Book Collection Tracker API Documentation

## Overview
This document describes the REST API endpoints, request/response schemas, validation rules, and error responses for the Book Collection Tracker application.

**Base URL**: `http://localhost:3000` (or configured port)

---

## Authentication
All protected endpoints require a Bearer token in the `Authorization` header:
```http
Authorization: Bearer <JWT_TOKEN>
```

---

## 1. Authentication Module (`/api/auth`)

### POST /api/auth/register
Register a new user.

* **Auth Required**: No
* **Request Body** (JSON):
  * `name` (String, required): User's name.
  * `email` (String, required): Must be a valid, unique email address.
  * `password` (String, required): Password.
  * `confirmPassword` (String, required): Must match `password`.
* **Validation Rules**:
  * Email must not be already registered.
* **Response (201 Created)**:
  ```json
  {
    "token": "eyJhbG...",
    "user": {
      "id": 1,
      "name": "User Name",
      "email": "user@example.com"
    }
  }
  ```
* **Error Response (400 Bad Request)**:
  ```json
  { "error": "Email already registered" }
  ```

### POST /api/auth/login
Log in an existing user.

* **Auth Required**: No
* **Request Body** (JSON):
  * `email` (String, required)
  * `password` (String, required)
* **Response (200 OK)**:
  ```json
  {
    "token": "eyJhbG...",
    "user": {
      "id": 1,
      "name": "User Name",
      "email": "user@example.com"
    }
  }
  ```
* **Error Response (401 Unauthorized)**:
  ```json
  { "error": "Invalid email or password" }
  ```

### POST /api/auth/logout
Log out the user and invalidate the current session token.

* **Auth Required**: Yes
* **Response (200 OK)**:
  ```json
  { "message": "Logged out successfully" }
  ```

### POST /api/auth/reset-password-request
Request a password reset token.

* **Auth Required**: No
* **Request Body** (JSON):
  * `email` (String, required)
* **Response (200 OK)**:
  ```json
  {
    "message": "Password reset token generated successfully. Send token via reset endpoint.",
    "token": "reset_token_uuid"
  }
  ```

### POST /api/auth/reset-password
Reset the user's password using a valid reset token.

* **Auth Required**: No
* **Request Body** (JSON):
  * `token` (String, required)
  * `newPassword` (String, required)
  * `confirmPassword` (String, required): Must match `newPassword`.
* **Response (200 OK)**:
  ```json
  { "message": "Password reset successfully" }
  ```

---

## 2. Book Management Module (`/api/books`)

### GET /api/books
Retrieve the authenticated user's books with support for searching, filtering, sorting, and pagination.

* **Auth Required**: Yes
* **Query Parameters**:
  * `search` (String, optional): Case-insensitive partial match on title or author.
  * `genre` (String, optional): Filter by genre.
  * `rating` (Integer, optional): Filter by rating (1-5).
  * `shelf` (String, optional): Filter by shelf (`Want To Read`, `Currently Reading`, `Finished Reading`).
  * `sort` (String, optional):
    * `title_asc` / `title_desc`: Sort by title alphabetically.
    * `author_asc`: Sort by author alphabetically.
    * `newest` / `oldest`: Sort by addition date.
    * `highest_rated`: Sort by rating descending.
  * `page` (Integer, optional, default: 1): Must be > 0.
  * `limit` (Integer, optional, default: 10): Must be > 0.
* **Response (200 OK)**:
  ```json
  {
    "books": [
      {
        "id": 1,
        "title": "Clean Code",
        "author": "Robert C. Martin",
        "genre": "Software Engineering",
        "publication_year": 2008,
        "shelf": "Finished Reading",
        "current_page": 460,
        "total_pages": 460,
        "completion_date": "2026-06-10",
        "rating": 5,
        "review": "Excellent book.",
        "cover_image": "/uploads/cover.jpg",
        "created_at": "2026-06-10T10:00:00.000Z"
      }
    ],
    "pagination": {
      "totalBooks": 1,
      "page": 1,
      "limit": 10,
      "totalPages": 1
    }
  }
  ```

### POST /api/books
Add a new book. Supports multipart/form-data for image uploads.

* **Auth Required**: Yes
* **Request Fields** (Multipart/Form-Data or JSON):
  * `title` (String, required)
  * `author` (String, required)
  * `genre` (String, required)
  * `publication_year` (Integer, required): Must be between 1000 and the current calendar year.
  * `shelf` (String, optional, default: `Want To Read`): Enforced values: `Want To Read`, `Currently Reading`, `Finished Reading`.
  * `current_page` (Integer, optional, default: 0): Must be >= 0 and <= `total_pages`.
  * `total_pages` (Integer, optional, default: 0): Must be >= 0.
  * `completion_date` (Date string, optional): Cannot be in the future.
  * `rating` (Integer, optional): Must be between 1 and 5.
  * `review` (String, optional): Max 2000 characters.
  * `cover` (Binary File, optional): Must be an image file (JPEG/PNG), max 5MB.
* **Response (201 Created)**:
  ```json
  {
    "message": "Book added successfully",
    "book": { ... }
  }
  ```

### GET /api/books/:id
Get details of a specific book owned by the user.

* **Auth Required**: Yes
* **Response (200 OK)**:
  ```json
  { "book": { ... } }
  ```
* **Error Responses**:
  * **403 Forbidden**: Access denied to this book (owned by another user).
  * **404 Not Found**: Book not found.

### PUT /api/books/:id
Update book details. Supports cover image upload replacement.

* **Auth Required**: Yes
* **Request Fields** (Multipart/Form-Data or JSON): Same parameters as `POST /api/books`.
* **Response (200 OK)**:
  ```json
  {
    "message": "Book updated successfully",
    "book": { ... }
  }
  ```

### DELETE /api/books/:id
Delete a book. Automatically removes the cover image from storage.

* **Auth Required**: Yes
* **Response (200 OK)**:
  ```json
  { "message": "Book deleted successfully" }
  ```

### GET /api/books/shelves/stats
Retrieve shelf counts.

* **Auth Required**: Yes
* **Response (200 OK)**:
  ```json
  {
    "wantToRead": 5,
    "currentlyReading": 2,
    "finishedReading": 10
  }
  ```

### PATCH /api/books/:id/shelf
Update reading status shelf assignment.

* **Auth Required**: Yes
* **Request Body** (JSON):
  * `shelf` (String, required): Enforced values: `Want To Read`, `Currently Reading`, `Finished Reading`.
* **Response (200 OK)**:
  ```json
  {
    "message": "Shelf updated successfully",
    "book": { ... }
  }
  ```

### PATCH /api/books/:id/progress
Update reading page progress. Uses database transactions and row-level locking.

* **Auth Required**: Yes
* **Request Body** (JSON):
  * `current_page` (Integer, required): Must be >= 0 and <= `total_pages`.
  * `total_pages` (Integer, required): Must be >= 0.
* **Validation Rules**:
  * Book shelf must be `Currently Reading`.
* **Response (200 OK)**:
  ```json
  {
    "message": "Reading progress updated successfully",
    "book": { ... },
    "progress_percentage": 45.5
  }
  ```

### POST /api/books/:id/review
Submit a rating and review for a completed book. Automatically transitions the book to the `Finished Reading` shelf. Uses transactions and row locking.

* **Auth Required**: Yes
* **Request Body** (JSON):
  * `completion_date` (Date string, required): Cannot be in the future.
  * `rating` (Integer, required): Must be between 1 and 5.
  * `review` (String, optional): Max 2000 characters.
* **Response (200 OK)**:
  ```json
  {
    "message": "Review submitted successfully",
    "book": { ... }
  }
  ```

---

## 3. Reading Goals Module (`/api/goals`)

### POST /api/goals
Create an annual reading goal.

* **Auth Required**: Yes
* **Request Body** (JSON):
  * `target_books` (Integer, required): Must be > 0.
  * `year` (Integer, optional, default: current calendar year).
* **Validation Rules**:
  * Only one goal is permitted per user per calendar year (unique constraint `uq_user_year`).
* **Response (201 Created)**:
  ```json
  {
    "message": "Goal created successfully",
    "goal": {
      "id": 1,
      "year": 2026,
      "targetBooks": 12,
      "completedBooks": 0,
      "progressPercentage": 0,
      "status": "Not Started"
    }
  }
  ```

### GET /api/goals
Retrieve the authenticated user's goals with auto-calculated progress percentage and achievement status.

* **Auth Required**: Yes
* **Response (200 OK)**:
  ```json
  {
    "goals": [
      {
        "id": 1,
        "year": 2026,
        "targetBooks": 12,
        "completedBooks": 3,
        "progressPercentage": 25,
        "status": "In Progress"
      }
    ]
  }
  ```

### PUT /api/goals/:id
Update an existing annual goal's target value.

* **Auth Required**: Yes
* **Request Body** (JSON):
  * `target_books` (Integer, required): Must be > 0.
* **Response (200 OK)**:
  ```json
  {
    "message": "Goal updated successfully",
    "goal": { ... }
  }
  ```

---

## 4. Statistics Dashboard Module (`/api/dashboard`)

### GET /api/dashboard/stats
Retrieve the real-time aggregated stats dashboard.

* **Auth Required**: Yes
* **Response (200 OK)**:
  ```json
  {
    "collectionStats": {
      "totalBooks": 17,
      "totalBooksRead": 10,
      "currentlyReading": 2,
      "wantToRead": 5
    },
    "readingStats": {
      "totalPagesRead": 2450,
      "completionRate": 58.82,
      "averageRating": 4.25
    },
    "genreAnalysis": {
      "genreDistribution": [
        { "genre": "Software Engineering", "count": 10 },
        { "genre": "Computer Science", "count": 7 }
      ],
      "favoriteGenre": "Software Engineering"
    },
    "readingInsights": {
      "booksFinishedThisMonth": 3,
      "booksFinishedThisYear": 8,
      "readingStreak": 3
    },
    "readingGoal": {
      "id": 1,
      "year": 2026,
      "targetBooks": 12,
      "completedBooks": 8,
      "progressPercentage": 66.67,
      "status": "In Progress"
    }
  }
  ```

---

## Database Integrity & Error Handling

### Standard Error Responses

#### 400 Bad Request
Occurs when input validation fails (e.g. invalid dates, negative pages, missing fields).
```json
{ "error": "Goal value must be greater than zero" }
```

#### 401 Unauthorized
Occurs when authentication is missing or token is invalid.
```json
{ "error": "Unauthorized" }
```

#### 403 Forbidden
Occurs when attempting to modify a resource belonging to another user.
```json
{ "error": "Access denied" }
```

#### 404 Not Found
Occurs when the requested resource does not exist.
```json
{ "error": "Book not found" }
```

#### 500 Internal Server Error
Occurs on database errors or unexpected system exceptions.
```json
{ "error": "Internal Server Error" }
```
