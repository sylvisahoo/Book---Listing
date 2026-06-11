# QA Test Execution Report

| Test Case                                                                | Status (Pass/Fail) |
| ------------------------------------------------------------------------ | ------------------ |
| **Module 1: Authentication (Backend / API)**                             |                    |
| API: Register new user successfully with valid details                   | Pass               |
| API: Reject user registration with missing details                       | Pass               |
| API: Reject user registration when passwords do not match                | Pass               |
| API: Prevent registration with duplicate email                           | Pass               |
| API: Login successfully with valid credentials                           | Pass               |
| API: Reject login with invalid password                                  | Pass               |
| API: Reject login with non-existent email                                | Pass               |
| API: Generate password reset token for valid email                       | Pass               |
| API: Reject password reset request for non-existent email                | Pass               |
| API: Reset password successfully using a valid token                     | Pass               |
| API: Reject password reset if token is invalid                           | Pass               |
| API: Access profile details with valid token                             | Pass               |
| API: Logout and blacklist active JWT token successfully                  | Pass               |
| **Module 1: Authentication (Frontend / UI)**                             |                    |
| UI: Display Sign In screen fields and title by default                   | Pass               |
| UI: Render login validation errors for empty fields                      | Pass               |
| UI: Render login validation error for invalid email formats              | Pass               |
| UI: Authenticate user successfully and navigate to HomeScreen            | Pass               |
| UI: Display failure alert dialog when login request fails                | Pass               |
| UI: Render registration validation errors for empty inputs               | Pass               |
| UI: Render registration validation error for short passwords             | Pass               |
| UI: Render registration validation error for mismatched passwords        | Pass               |
| UI: Trigger registration API successfully on valid form submission       | Pass               |
| UI: Forgot password workflow showing copyable token dialog               | Pass               |
| UI: Reset Password with token updates credentials successfully           | Pass               |
| **Module 2: Book Management (Backend / API)**                            |                    |
| API: Add book successfully with valid details (no cover image)           | Pass               |
| API: Add book successfully with valid details and cover image upload     | Pass               |
| API: Reject book creation when missing required fields                   | Pass               |
| API: Reject book creation with publication year in the future            | Pass               |
| API: Reject book creation with publication year older than 1000          | Pass               |
| API: Retrieve only the authenticated user's book list                    | Pass               |
| API: Get details of own book                                             | Pass               |
| API: Reject access to another user's book details                        | Pass               |
| API: Return 404 if requested book does not exist                         | Pass               |
| API: Edit details of own book successfully                               | Pass               |
| API: Edit cover image and clean up old cover file on disk                | Pass               |
| API: Prevent editing details of another user's book                      | Pass               |
| API: Delete own book and delete cover file from uploads folder           | Pass               |
| API: Prevent deleting another user's book                                | Pass               |
| **Module 3: Reading Status Management (Backend / API)**                  |                    |
| API: Assign default shelf of "Want To Read" when adding a book           | Pass               |
| API: Allow setting a custom shelf on book creation                       | Pass               |
| API: Reject invalid custom shelf value on book creation                  | Pass               |
| API: Move book to "Want To Read" shelf successfully                      | Pass               |
| API: Move book to "Currently Reading" shelf successfully                 | Pass               |
| API: Move book to "Finished Reading" shelf successfully                  | Pass               |
| API: Reject invalid shelf values on book update                          | Pass               |
| API: Prevent moving shelf of another user's book                         | Pass               |
| API: Calculate and return correct shelf counts for active user           | Pass               |
| **Module 3: Reading Status Management (Frontend / UI)**                  |                    |
| UI: Render correct shelf statistics counts on library header             | Pass               |
| UI: Display shelf tag and open shelf options bottom sheet                | Pass               |
| UI: Transition shelf to "Currently Reading" successfully                 | Pass               |
| **Module 4: Reading Progress Tracking (Backend / API)**                  |                    |
| API: Update progress successfully for "Currently Reading" book           | Pass               |
| API: Calculate 0% progress if total pages is 0                           | Pass               |
| API: Reject progress update if current_page or total_pages missing       | Pass               |
| API: Reject progress update with negative current page                   | Pass               |
| API: Reject progress update with negative total pages                    | Pass               |
| API: Reject progress update if current page exceeds total pages          | Pass               |
| API: Reject progress update if book is not on Currently Reading shelf    | Pass               |
| API: Prevent updating reading progress on another user's book            | Pass               |
| **Module 5: Ratings & Reviews (Backend / API)**                          |                    |
| API: Submit rating/review successfully and move to Finished Reading      | Pass               |
| API: Allow optional review text (rating and completion date only)        | Pass               |
| API: Reject review when missing completion_date                          | Pass               |
| API: Reject review when missing rating                                   | Pass               |
| API: Reject rating values outside the 1 to 5 range                       | Pass               |
| API: Reject completion date in the future                                | Pass               |
| API: Reject reviews exceeding 2000 characters in length                  | Pass               |
| API: Prevent reviewing another user's book                               | Pass               |
| API: Include ratings and reviews when retrieving book details            | Pass               |
| **Module 5: Ratings & Reviews (Frontend / UI)**                          |                    |
| UI: Render review display elements correctly for finished books          | Pass               |
| UI: Display alternative fallback message when review text is null        | Pass               |
| UI: Edit review pencil button opens dialog and submits successfully      | Pass               |
| **Module 6: Search & Filters (Backend / API)**                           |                    |
| API: Search partially and case-insensitively by title                    | Pass               |
| API: Search partially and case-insensitively by author                   | Pass               |
| API: Filter books by genre selection                                     | Pass               |
| API: Filter books by rating selection                                    | Pass               |
| API: Filter books by reading status shelf selection                      | Pass               |
| API: Return empty list when no books match filtered criteria             | Pass               |
| API: Sort books by Title A-Z                                             | Pass               |
| API: Sort books by Title Z-A                                             | Pass               |
| API: Sort books by Oldest first                                          | Pass               |
| API: Sort books by Highest Rated                                         | Pass               |
| API: Combine search, shelf filter, and title sorting                     | Pass               |
| API: Prevent returning other users' books during search/retrieve         | Pass               |
| **Module 6: Search & Filters (Frontend / UI)**                           |                    |
| UI: Search field updates book provider state and calls REST API          | Pass               |
| UI: Apply shelf filter from bottom sheet and reload list                 | Pass               |
| UI: Apply genre filter from bottom sheet and reload list                 | Pass               |
| UI: Apply rating filter from bottom sheet and reload list                | Pass               |
| UI: Display "No Matching Books" empty state when search matches nothing  | Pass               |
| **Module 7: Statistics Dashboard (Backend / API)**                       |                    |
| API: Return empty stats payload structure when user has no books         | Pass               |
| API: Aggregate statistics, calculate averages/rates, genres, and streaks | Pass               |
| API: Return 0 streak if last completion date was before yesterday        | Pass               |
| API: Return current year's reading goal details inside stats payload     | Pass               |
| **Module 7: Statistics Dashboard (Frontend / UI)**                       |                    |
| UI: Renders loading indicator when stats are loading and cache is empty  | Pass               |
| UI: Renders retry error layout when dashboard fetching fails             | Pass               |
| UI: Renders all summary cards, streaks, goals, and genre distributions   | Pass               |
| UI: Tapping Retry button triggers new stats fetch request                | Pass               |
| **Module 8: Reading Goals (Backend / API)**                              |                    |
| API: Create annual reading goal successfully for current year            | Pass               |
| API: Create annual reading goal successfully for custom year             | Pass               |
| API: Reject reading goal creation when target_books is missing           | Pass               |
| API: Reject zero target books                                            | Pass               |
| API: Reject negative target books                                        | Pass               |
| API: Prevent duplicate reading goals for the same year                   | Pass               |
| API: Calculate "In Progress" status and progress percentage correctly    | Pass               |
| API: Calculate "Achieved" status when completed books meet target        | Pass               |
| API: Update target books value of own reading goal successfully          | Pass               |
| API: Reject goal target update with negative value                       | Pass               |
| API: Prevent updating another user's reading goal                        | Pass               |
| API: Delete own reading goal successfully                                | Pass               |
| API: Prevent deleting another user's reading goal                        | Pass               |
| API: Return 404 for non-existent reading goal                            | Pass               |
| **Module 8: Reading Goals (Frontend / UI)**                              |                    |
| UI: Render empty state layout when goals list is empty                   | Pass               |
| UI: Render reading goals list successfully with progress bars            | Pass               |
| UI: Validate form fields in annual goal creation dialog                  | Pass               |
| UI: Create new reading goal successfully via dialog submission           | Pass               |
| UI: Edit existing reading goal target successfully via dialog            | Pass               |
| **Module 9: API & Database Management (Backend / API)**                  |                    |
| API: Support page and limit query parameters for pagination              | Pass               |
| API: Reject invalid page or limit values with 400 Bad Request            | Pass               |
| API: Enforce database foreign key integrity constraints on insert        | Pass               |
| API: Handle concurrent updates sequentially via row-level locks          | Pass               |
| API: Assert API response times are under 200ms threshold                 | Pass               |
| API: Run CLI backup and restore scripts and verify data integrity        | Pass               |
| **Module 9: API & Database Management (Frontend / UI)**                  |                    |
| UI: Renders current page index and paginates via chevron buttons         | Pass               |
| UI: Displays warning error dialog when database constraints fail         | Pass               |
