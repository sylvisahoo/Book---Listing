# Book Collection Tracker - Product Requirements Document (PRD)

# 1. Product Overview

## Product Name

**Book Collection Tracker**

## Product Type

Web and Mobile Responsive Digital Library Management Application

## Tech Stack

* Flutter 3.x (3.41.x)
* Dart 3.x
* Node.js v22.20.0
* PostgreSQL

---

# 2. Problem Statement

Book enthusiasts often struggle to manage growing personal book collections, track reading progress,
remember completed books, and analyze reading habits.

Most users maintain records manually through spreadsheets, notes, or memory, resulting in:

* Poor collection organization
* Difficulty tracking reading progress
* Lack of historical reading insights
* No centralized review system
* Inability to monitor reading goals

A centralized platform is needed to organize collections, track reading journeys, and generate
meaningful reading analytics.

---

# 3. Solution Overview

Book Collection Tracker provides users with:

* Personal digital library management
* Reading status categorization
* Reading progress tracking
* Book ratings and reviews
* Reading goal management
* Statistics and insights dashboard
* Search, filter, and sorting capabilities
* Fully responsive experience across devices

---

# 4. Functional Requirements

## Module 1: Authentication

### User Registration

#### Fields

* Full Name
* Email
* Password
* Confirm Password

### Login

#### Fields

* Email
* Password

#### Validation

* Email exists
* Password correct

### Forgot Password

#### Flow

1. Enter Email
2. Receive Reset Link
3. Create New Password

### Acceptance Criteria

* User can register successfully
* Duplicate email prevented
* User can login
* Password reset link generated
* Invalid credentials rejected

---

## Module 2: Book Management

### Add Book

#### Fields

| Field            | Required |
|------------------|----------|
| Title            | Yes      |
| Author           | Yes      |
| Genre            | Yes      |
| Publication Year | Yes      |
| Cover Image      | Optional |

### Edit Book

User can update:

* Title
* Author
* Genre
* Publication Year
* Cover

### Delete Book

Confirmation required before deletion.

### Acceptance Criteria

* User can create book
* User can edit book
* User can delete book
* Invalid publication year rejected

---

## Module 3: Reading Status Management

### Shelves

* Want To Read
* Currently Reading
* Finished Reading

### Rules

* One book can belong to only one shelf
* Shelf change updates statistics automatically

### Acceptance Criteria

* User can move books between shelves
* Duplicate shelf assignment prevented

---

## Module 4: Reading Progress Tracking

Applicable only for:

* Currently Reading books

### Fields

* Current Page
* Total Pages

### System Calculation

Progress % = Current Page / Total Pages × 100

### Display

* Progress percentage
* Visual progress bar

### Acceptance Criteria

* Progress updates instantly
* Invalid page values rejected
* Progress percentage calculated correctly

---

## Module 5: Book Completion

Triggered when moving a book to Finished Reading.

### Completion Form

| Field           | Required |
|-----------------|----------|
| Completion Date | Yes      |
| Rating          | Yes      |
| Review          | No       |

### Rating

* 1 Star
* 2 Star
* 3 Star
* 4 Star
* 5 Star

### Review

Maximum 2000 characters.

### Acceptance Criteria

* Completion date mandatory
* Rating mandatory
* Review saved successfully

---

## Module 6: Search & Organization

### Search By

* Title
* Author

### Search Type

* Partial Match
* Case Insensitive

### Filters

#### Genre

* Fiction
* Fantasy
* Thriller
* Science
* Biography

#### Rating

* 1–5

#### Reading Status

* Want To Read
* Currently Reading
* Finished Reading

### Sorting

* Title A-Z
* Title Z-A
* Author A-Z
* Newest Added
* Oldest Added
* Highest Rated

### Acceptance Criteria

* Search returns matching results
* Filters combine correctly
* Sorting updates instantly

---

## Module 7: Statistics Dashboard

### Collection Statistics

* Total Books Owned
* Total Books Read
* Currently Reading
* Want To Read

### Reading Statistics

* Total Pages Read
* Reading Completion Rate
* Average Rating

### Genre Analysis

* Genre Distribution Chart
* Favorite Genre

### Reading Insights

* Books Finished This Month
* Books Finished This Year
* Reading Streak

### Acceptance Criteria

* Statistics generated accurately
* Charts update automatically

---

## Module 8: Reading Goals

### Annual Reading Goal

User can set:

* Books Per Year Goal

#### Example

* Goal: 50 Books
* Completed: 30 Books
* Progress: 60%

### Goal Indicators

* Not Started
* In Progress
* Achieved

### Acceptance Criteria

* Goal saved successfully
* Progress auto-calculated
* Goal achievement displayed

---

# 5. User Flow

## Registration Flow

Landing Page → Register → Verify Inputs → Account Created → Dashboard

## Add Book Flow

Dashboard → Add Book → Enter Details → Save → Book Added

## Reading Progress Flow

Library → Open Book → Update Current Page → Progress Calculated → Save

## Completion Flow

Currently Reading → Mark Finished → Completion Form → Rating + Review → Finished Shelf

---

# 6. Dashboard Requirements

## Reading Overview

* Total Books
* Books Read
* Reading Goal Progress

## Reading Analytics

* Genre Breakdown
* Reading Trends

## Recent Activity

* Recently Added Books
* Recently Finished Books

## Goal Tracking

* Goal Percentage
* Achievement Status

---

# 10. Mobile Responsiveness Requirements

## Mobile

* Single-column layout
* Bottom navigation
* Touch-friendly controls

### Responsive Rules

* Minimum width support: 320px
* Responsive images
* Adaptive typography
* Responsive charts
* Optimized touch targets

---

# 7. API Design

## Authentication APIs

* POST /api/auth/register
* POST /api/auth/login
* POST /api/auth/forgot-password
* POST /api/auth/reset-password

## Book APIs

* POST /api/books
* GET /api/books
* PUT /api/books/:id
* DELETE /api/books/:id

## Progress APIs

* PATCH /api/books/:id/progress

## Review APIs

* POST /api/books/:id/review

## Goal APIs

* POST /api/goals
* GET /api/goals
* PUT /api/goals/:id

## Dashboard APIs

* GET /api/dashboard/stats

---

# 8. Edge Cases

### Book Management

* Duplicate books added intentionally
* Missing cover image
* Extremely long titles

### Reading Progress

* Current page exceeds total pages
* Total pages equals zero
* Negative page numbers

### Completion

* Completion date in future
* Rating outside 1–5 range

### Search

* Empty search
* No matching results
* Large result sets

### Goals

* Goal set to zero
* Goal changed mid-year

---

# 9. Limitations

* No social sharing in MVP
* No audiobook tracking
* No eBook synchronization
* No barcode scanning support
* No recommendation engine in MVP

---

**This PRD is implementation-ready for Design, Flutter Frontend, Node.js Backend, QA, and Project
Management teams.**
