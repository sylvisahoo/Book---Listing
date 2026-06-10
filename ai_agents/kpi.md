# Book Collection Application - KPI Document

## Module 1: Authentication

| # | KPI                                                 | Verification Method                                      |
| - | --------------------------------------------------- | -------------------------------------------------------- |
| 1 | User can successfully register with valid details   | Verify account creation in database and success response |
| 2 | User cannot register with an existing email address | Verify validation error response                         |
| 3 | User can login with valid credentials               | Verify JWT token generation and successful login         |
| 4 | User cannot login with invalid credentials          | Verify authentication failure response                   |
| 5 | User can request password reset link                | Verify reset token generation and email trigger          |
| 6 | User can reset password using valid token           | Verify password update in database                       |
| 7 | User can logout successfully                        | Verify session/token invalidation                        |


## Module 2: Book Management

| # | KPI                                                  | Verification Method                     |
| - | ---------------------------------------------------- | --------------------------------------- |
| 1 | User can add a new book with valid details           | Verify book record creation in database |
| 2 | User cannot add a book with missing mandatory fields | Verify validation error response        |
| 3 | User can upload a valid book cover image             | Verify image storage and retrieval      |
| 4 | User can edit existing book details                  | Verify updated data in database         |
| 5 | User can delete a book from collection               | Verify book record removal              |
| 6 | System accepts publication year within valid range   | Verify year validation logic            |
| 7 | Book details are displayed correctly in library      | Verify UI rendering of book information |


## Module 3: Reading Status Management

| # | KPI                                                   | Verification Method                    |
| - | ----------------------------------------------------- | -------------------------------------- |
| 1 | User can move a book to Want To Read shelf            | Verify shelf status update in database |
| 2 | User can move a book to Currently Reading shelf       | Verify shelf status update in database |
| 3 | User can move a book to Finished Reading shelf        | Verify shelf status update in database |
| 4 | A book belongs to only one shelf at a time            | Verify unique shelf assignment         |
| 5 | Shelf counts update automatically after status change | Verify dashboard and shelf counts      |


## Module 4: Reading Progress Tracking
| # | KPI                                            | Verification Method                  |
| - | ---------------------------------------------- | ------------------------------------ |
| 1 | User can update current page number            | Verify page value update in database |
| 2 | Progress percentage is calculated correctly    | Verify progress calculation formula  |
| 3 | Progress bar updates based on reading progress | Verify UI progress indicator         |
| 4 | Current page cannot exceed total pages         | Verify validation error response     |
| 5 | Negative page values are not accepted          | Verify validation error response     |
| 6 | Reading progress persists after page refresh   | Verify stored progress data          |

## Module 5: Ratings & Reviews

| # | KPI                                             | Verification Method                      |
| - | ----------------------------------------------- | ---------------------------------------- |
| 1 | User can mark a book as completed               | Verify status update to Finished Reading |
| 2 | User can enter completion date                  | Verify completion date storage           |
| 3 | User can provide rating between 1 and 5 stars   | Verify rating validation and storage     |
| 4 | User can write a review for completed book      | Verify review record creation            |
| 5 | User cannot submit rating outside allowed range | Verify validation error response         |
| 6 | Review is displayed with corresponding book     | Verify review retrieval and display      |


## Module 6: Search & Filters

| # | KPI                                     | Verification Method                  |
| - | --------------------------------------- | ------------------------------------ |
| 1 | User can search books by title          | Verify matching records are returned |
| 2 | User can search books by author         | Verify matching records are returned |
| 3 | User can filter books by genre          | Verify filtered result accuracy      |
| 4 | User can filter books by rating         | Verify filtered result accuracy      |
| 5 | User can filter books by reading status | Verify filtered result accuracy      |
| 6 | User can sort books by title            | Verify sorting order correctness     |
| 7 | User can sort books by rating           | Verify sorting order correctness     |
| 8 | Empty search displays no-result message | Verify appropriate UI message        |

## Module 7: Statistics Dashboard

| # | KPI                                              | Verification Method                   |
| - | ------------------------------------------------ | ------------------------------------- |
| 1 | Dashboard displays total books owned             | Verify count against database records |
| 2 | Dashboard displays total books read              | Verify count against finished books   |
| 3 | Dashboard displays currently reading books       | Verify count accuracy                 |
| 4 | Dashboard displays total pages read              | Verify page calculation accuracy      |
| 5 | Dashboard displays reading completion statistics | Verify calculation logic              |
| 6 | Dashboard displays genre distribution chart      | Verify chart data matches database    |
| 7 | Dashboard displays favorite genre analysis       | Verify most-read genre calculation    |
| 8 | Dashboard displays reading activity insights     | Verify generated analytics data       |

## Module 8: Reading Goals

| # | KPI                                              | Verification Method                        |
| - | ------------------------------------------------ | ------------------------------------------ |
| 1 | User can create annual reading goal              | Verify goal creation in database           |
| 2 | User can update annual reading goal              | Verify updated goal value                  |
| 3 | Goal progress percentage is calculated correctly | Verify completed books vs goal calculation |
| 4 | Goal achievement status updates automatically    | Verify achievement logic                   |
| 5 | Goal progress is displayed on dashboard          | Verify dashboard integration               |
| 6 | Goal value cannot be zero or negative            | Verify validation error response           |


## Module 9: API & Database Management

| # | KPI                                               | Verification Method                           |
| - | ------------------------------------------------- | --------------------------------------------- |
| 1 | Book APIs return correct data                     | Verify API response against database records  |
| 2 | Dashboard API returns accurate statistics         | Verify dashboard data calculations            |
| 3 | Goal APIs perform CRUD operations successfully    | Verify database updates and responses         |
| 4 | API response time remains under defined threshold | Verify performance metrics                    |
| 5 | Database relationships maintain data integrity    | Verify foreign key constraints                |
| 6 | System supports pagination for large datasets     | Verify paginated API responses                |
| 7 | Database backup process completes successfully    | Verify backup file generation and restoration |
| 8 | Concurrent updates do not cause data corruption   | Verify transactional consistency              |


**Tech Stack:**
- Flutter 3.x (3.41.x)
- Dart 3.x
- Node.js v22.20.0
- PostgreSQL