import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/book_remote_data_source.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/usecases/add_book_usecase.dart';
import '../../domain/usecases/add_review_usecase.dart';
import '../../domain/usecases/create_goal_usecase.dart';
import '../../domain/usecases/delete_book_usecase.dart';
import '../../domain/usecases/edit_book_usecase.dart';
import '../../domain/usecases/get_book_details_usecase.dart';
import '../../domain/usecases/get_books_usecase.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import '../../domain/usecases/get_goals_usecase.dart';
import '../../domain/usecases/get_shelf_stats_usecase.dart';
import '../../domain/usecases/update_book_progress_usecase.dart';
import '../../domain/usecases/update_book_shelf_usecase.dart';
import '../../domain/usecases/update_goal_usecase.dart';

// DI Providers
final bookRemoteDataSourceProvider = Provider<BookRemoteDataSource>((ref) {
  return BookRemoteDataSource(
    authLocalDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepositoryImpl(
    remoteDataSource: ref.watch(bookRemoteDataSourceProvider),
  );
});

final getBooksUseCaseProvider = Provider<GetBooksUseCase>((ref) {
  return GetBooksUseCase(ref.watch(bookRepositoryProvider));
});

final getBookDetailsUseCaseProvider = Provider<GetBookDetailsUseCase>((ref) {
  return GetBookDetailsUseCase(ref.watch(bookRepositoryProvider));
});

final addBookUseCaseProvider = Provider<AddBookUseCase>((ref) {
  return AddBookUseCase(ref.watch(bookRepositoryProvider));
});

final editBookUseCaseProvider = Provider<EditBookUseCase>((ref) {
  return EditBookUseCase(ref.watch(bookRepositoryProvider));
});

final deleteBookUseCaseProvider = Provider<DeleteBookUseCase>((ref) {
  return DeleteBookUseCase(ref.watch(bookRepositoryProvider));
});

final updateBookShelfUseCaseProvider = Provider<UpdateBookShelfUseCase>((ref) {
  return UpdateBookShelfUseCase(ref.watch(bookRepositoryProvider));
});

final updateBookProgressUseCaseProvider = Provider<UpdateBookProgressUseCase>((
  ref,
) {
  return UpdateBookProgressUseCase(ref.watch(bookRepositoryProvider));
});

final addReviewUseCaseProvider = Provider<AddReviewUseCase>((ref) {
  return AddReviewUseCase(ref.watch(bookRepositoryProvider));
});

final getShelfStatsUseCaseProvider = Provider<GetShelfStatsUseCase>((ref) {
  return GetShelfStatsUseCase(ref.watch(bookRepositoryProvider));
});

final getDashboardStatsUseCaseProvider = Provider<GetDashboardStatsUseCase>((
  ref,
) {
  return GetDashboardStatsUseCase(ref.watch(bookRepositoryProvider));
});

final getGoalsUseCaseProvider = Provider<GetGoalsUseCase>((ref) {
  return GetGoalsUseCase(ref.watch(bookRepositoryProvider));
});

final createGoalUseCaseProvider = Provider<CreateGoalUseCase>((ref) {
  return CreateGoalUseCase(ref.watch(bookRepositoryProvider));
});

final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>((ref) {
  return UpdateGoalUseCase(ref.watch(bookRepositoryProvider));
});

// Book State Class
class BookState {
  final List<Book> books;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, int> shelfStats;
  final Map<String, dynamic>? dashboardStats;
  final bool isDashboardLoading;
  final List<dynamic> goals;
  final bool isGoalsLoading;

  // Search/Filters/Sort
  final String searchText;
  final String? selectedGenre;
  final int? selectedRating;
  final String? selectedShelf;
  final String sortOption;

  // Pagination
  final int currentPage;
  final int totalPages;
  final int totalBooks;
  final int limit;

  BookState({
    this.books = const [],
    this.isLoading = false,
    this.errorMessage,
    this.shelfStats = const {
      'wantToRead': 0,
      'currentlyReading': 0,
      'finishedReading': 0,
    },
    this.dashboardStats,
    this.isDashboardLoading = false,
    this.goals = const [],
    this.isGoalsLoading = false,
    this.searchText = '',
    this.selectedGenre,
    this.selectedRating,
    this.selectedShelf,
    this.sortOption = 'newest',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalBooks = 0,
    this.limit = 6,
  });

  BookState copyWith({
    List<Book>? books,
    bool? isLoading,
    String? errorMessage,
    Map<String, int>? shelfStats,
    Map<String, dynamic>? dashboardStats,
    bool? isDashboardLoading,
    List<dynamic>? goals,
    bool? isGoalsLoading,
    String? searchText,
    String? selectedGenre,
    int? selectedRating,
    String? selectedShelf,
    String? sortOption,
    int? currentPage,
    int? totalPages,
    int? totalBooks,
    int? limit,
    bool clearError = false,
    bool clearGenre = false,
    bool clearRating = false,
    bool clearShelf = false,
  }) {
    return BookState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      shelfStats: shelfStats ?? this.shelfStats,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      isDashboardLoading: isDashboardLoading ?? this.isDashboardLoading,
      goals: goals ?? this.goals,
      isGoalsLoading: isGoalsLoading ?? this.isGoalsLoading,
      searchText: searchText ?? this.searchText,
      selectedGenre: clearGenre ? null : (selectedGenre ?? this.selectedGenre),
      selectedRating: clearRating
          ? null
          : (selectedRating ?? this.selectedRating),
      selectedShelf: clearShelf ? null : (selectedShelf ?? this.selectedShelf),
      sortOption: sortOption ?? this.sortOption,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalBooks: totalBooks ?? this.totalBooks,
      limit: limit ?? this.limit,
    );
  }
}

// StateNotifier Class
class BookNotifier extends StateNotifier<BookState> {
  final GetBooksUseCase _getBooksUseCase;
  final GetBookDetailsUseCase _getBookDetailsUseCase;
  final AddBookUseCase _addBookUseCase;
  final EditBookUseCase _editBookUseCase;
  final DeleteBookUseCase _deleteBookUseCase;
  final UpdateBookShelfUseCase _updateBookShelfUseCase;
  final UpdateBookProgressUseCase _updateBookProgressUseCase;
  final AddReviewUseCase _addReviewUseCase;
  final GetShelfStatsUseCase _getShelfStatsUseCase;
  final GetDashboardStatsUseCase _getDashboardStatsUseCase;
  final GetGoalsUseCase _getGoalsUseCase;
  final CreateGoalUseCase _createGoalUseCase;
  final UpdateGoalUseCase _updateGoalUseCase;

  BookNotifier({
    required GetBooksUseCase getBooksUseCase,
    required GetBookDetailsUseCase getBookDetailsUseCase,
    required AddBookUseCase addBookUseCase,
    required EditBookUseCase editBookUseCase,
    required DeleteBookUseCase deleteBookUseCase,
    required UpdateBookShelfUseCase updateBookShelfUseCase,
    required UpdateBookProgressUseCase updateBookProgressUseCase,
    required AddReviewUseCase addReviewUseCase,
    required GetShelfStatsUseCase getShelfStatsUseCase,
    required GetDashboardStatsUseCase getDashboardStatsUseCase,
    required GetGoalsUseCase getGoalsUseCase,
    required CreateGoalUseCase createGoalUseCase,
    required UpdateGoalUseCase updateGoalUseCase,
  }) : _getBooksUseCase = getBooksUseCase,
       _getBookDetailsUseCase = getBookDetailsUseCase,
       _addBookUseCase = addBookUseCase,
       _editBookUseCase = editBookUseCase,
       _deleteBookUseCase = deleteBookUseCase,
       _updateBookShelfUseCase = updateBookShelfUseCase,
       _updateBookProgressUseCase = updateBookProgressUseCase,
       _addReviewUseCase = addReviewUseCase,
       _getShelfStatsUseCase = getShelfStatsUseCase,
       _getDashboardStatsUseCase = getDashboardStatsUseCase,
       _getGoalsUseCase = getGoalsUseCase,
       _createGoalUseCase = createGoalUseCase,
       _updateGoalUseCase = updateGoalUseCase,
       super(BookState());

  // Setters triggering updates
  void setSearchText(String text) {
    state = state.copyWith(searchText: text, currentPage: 1);
    fetchBooks();
  }

  void setGenre(String? genre) {
    if (genre == null) {
      state = state.copyWith(clearGenre: true, currentPage: 1);
    } else {
      state = state.copyWith(selectedGenre: genre, currentPage: 1);
    }
    fetchBooks();
  }

  void setRating(int? rating) {
    if (rating == null) {
      state = state.copyWith(clearRating: true, currentPage: 1);
    } else {
      state = state.copyWith(selectedRating: rating, currentPage: 1);
    }
    fetchBooks();
  }

  void setShelf(String? shelf) {
    if (shelf == null) {
      state = state.copyWith(clearShelf: true, currentPage: 1);
    } else {
      state = state.copyWith(selectedShelf: shelf, currentPage: 1);
    }
    fetchBooks();
  }

  void setSort(String sort) {
    state = state.copyWith(sortOption: sort, currentPage: 1);
    fetchBooks();
  }

  void setPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page);
      fetchBooks();
    }
  }

  // Clear filters
  void clearFilters() {
    state = BookState().copyWith(currentPage: 1);
    fetchBooks();
  }

  // Fetch books list
  Future<void> fetchBooks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      Map<String, int> shelfStats = state.shelfStats;
      try {
        shelfStats = await _getShelfStatsUseCase.execute();
      } catch (_) {}

      Map<String, dynamic>? dashboardStats = state.dashboardStats;
      try {
        dashboardStats = await _getDashboardStatsUseCase.execute();
      } catch (_) {}

      final data = await _getBooksUseCase.execute(
        search: state.searchText,
        genre: state.selectedGenre,
        rating: state.selectedRating,
        shelf: state.selectedShelf,
        sort: state.sortOption,
        page: state.currentPage,
        limit: state.limit,
      );

      final books = data['books'] as List<Book>;
      final pagination = data['pagination'] as Map<String, dynamic>;

      state = state.copyWith(
        books: books,
        shelfStats: shelfStats,
        dashboardStats: dashboardStats,
        currentPage: pagination['page'] as int? ?? 1,
        totalPages: pagination['totalPages'] as int? ?? 1,
        totalBooks: pagination['totalBooks'] as int? ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        books: const [],
        isLoading: false,
      );
    }
  }

  // Add Book
  Future<bool> addBook(Map<String, String> fields, String? coverPath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _addBookUseCase.execute(fields, coverPath);
      await fetchBooks();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
      return false;
    }
  }

  // Edit Book
  Future<bool> editBook(
    int id,
    Map<String, String> fields,
    String? coverPath,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _editBookUseCase.execute(id, fields, coverPath);
      await fetchBooks();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
      return false;
    }
  }

  // Delete Book
  Future<bool> deleteBook(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _deleteBookUseCase.execute(id);
      await fetchBooks();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
      return false;
    }
  }

  // Retrieve single book details directly from backend
  Future<Book?> getBookDetails(int id) async {
    try {
      return await _getBookDetailsUseCase.execute(id);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  // Update shelf stats manually
  Future<void> fetchShelfStats() async {
    try {
      final stats = await _getShelfStatsUseCase.execute();
      state = state.copyWith(shelfStats: stats);
    } catch (_) {}
  }

  // Move book to another shelf
  Future<bool> updateBookShelf(int id, String shelf) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _updateBookShelfUseCase.execute(id, shelf);
      await fetchBooks();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
      return false;
    }
  }

  // Update book reading page progress
  Future<bool> updateBookProgress(
    int id,
    int currentPage,
    int totalPages,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _updateBookProgressUseCase.execute(id, currentPage, totalPages);
      await fetchBooks();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
      return false;
    }
  }

  // Submit a rating and review for a completed book
  Future<bool> addReview(
    int id,
    String completionDate,
    int rating,
    String? review,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _addReviewUseCase.execute(id, completionDate, rating, review);
      await fetchBooks();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
      return false;
    }
  }

  // Fetch dashboard statistics manually
  Future<void> fetchDashboardStats() async {
    state = state.copyWith(isDashboardLoading: true, clearError: true);
    try {
      final stats = await _getDashboardStatsUseCase.execute();
      state = state.copyWith(dashboardStats: stats, isDashboardLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isDashboardLoading: false,
      );
    }
  }

  // Fetch all reading goals
  Future<void> fetchGoals() async {
    state = state.copyWith(isGoalsLoading: true, clearError: true);
    try {
      final goals = await _getGoalsUseCase.execute();
      state = state.copyWith(goals: goals, isGoalsLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isGoalsLoading: false,
      );
    }
  }

  // Create an annual goal
  Future<bool> createGoal(int targetBooks, int year) async {
    state = state.copyWith(isGoalsLoading: true, clearError: true);
    try {
      await _createGoalUseCase.execute(targetBooks, year);
      await fetchGoals();
      await fetchDashboardStats();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isGoalsLoading: false,
      );
      return false;
    }
  }

  // Update target of existing goal
  Future<bool> updateGoal(int id, int targetBooks) async {
    state = state.copyWith(isGoalsLoading: true, clearError: true);
    try {
      await _updateGoalUseCase.execute(id, targetBooks);
      await fetchGoals();
      await fetchDashboardStats();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isGoalsLoading: false,
      );
      return false;
    }
  }
}

// Global Provider
final bookNotifierProvider = StateNotifierProvider<BookNotifier, BookState>((
  ref,
) {
  return BookNotifier(
    getBooksUseCase: ref.watch(getBooksUseCaseProvider),
    getBookDetailsUseCase: ref.watch(getBookDetailsUseCaseProvider),
    addBookUseCase: ref.watch(addBookUseCaseProvider),
    editBookUseCase: ref.watch(editBookUseCaseProvider),
    deleteBookUseCase: ref.watch(deleteBookUseCaseProvider),
    updateBookShelfUseCase: ref.watch(updateBookShelfUseCaseProvider),
    updateBookProgressUseCase: ref.watch(updateBookProgressUseCaseProvider),
    addReviewUseCase: ref.watch(addReviewUseCaseProvider),
    getShelfStatsUseCase: ref.watch(getShelfStatsUseCaseProvider),
    getDashboardStatsUseCase: ref.watch(getDashboardStatsUseCaseProvider),
    getGoalsUseCase: ref.watch(getGoalsUseCaseProvider),
    createGoalUseCase: ref.watch(createGoalUseCaseProvider),
    updateGoalUseCase: ref.watch(updateGoalUseCaseProvider),
  );
});
