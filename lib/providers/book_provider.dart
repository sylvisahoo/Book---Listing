import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class BookProvider extends ChangeNotifier {
  final BookService _bookService = BookService();

  List<Book> _books = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, int> _shelfStats = {'wantToRead': 0, 'currentlyReading': 0, 'finishedReading': 0};
  Map<String, dynamic>? _dashboardStats;
  bool _isDashboardLoading = false;
  List<dynamic> _goals = [];
  bool _isGoalsLoading = false;

  // Search/Filters/Sort
  String _searchText = '';
  String? _selectedGenre;
  int? _selectedRating;
  String? _selectedShelf;
  String _sortOption = 'newest';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalBooks = 0;
  final int _limit = 6; // Set page size

  // Getters
  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, int> get shelfStats => _shelfStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  bool get isDashboardLoading => _isDashboardLoading;
  List<dynamic> get goals => _goals;
  bool get isGoalsLoading => _isGoalsLoading;

  String get searchText => _searchText;
  String? get selectedGenre => _selectedGenre;
  int? get selectedRating => _selectedRating;
  String? get selectedShelf => _selectedShelf;
  String get sortOption => _sortOption;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalBooks => _totalBooks;

  // Setters triggering updates
  void setSearchText(String text) {
    _searchText = text;
    _currentPage = 1; // reset page index on filter change
    fetchBooks();
  }

  void setGenre(String? genre) {
    _selectedGenre = genre;
    _currentPage = 1;
    fetchBooks();
  }

  void setRating(int? rating) {
    _selectedRating = rating;
    _currentPage = 1;
    fetchBooks();
  }

  void setShelf(String? shelf) {
    _selectedShelf = shelf;
    _currentPage = 1;
    fetchBooks();
  }

  void setSort(String sort) {
    _sortOption = sort;
    _currentPage = 1;
    fetchBooks();
  }

  void setPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      fetchBooks();
    }
  }

  // Clear filters
  void clearFilters() {
    _searchText = '';
    _selectedGenre = null;
    _selectedRating = null;
    _selectedShelf = null;
    _sortOption = 'newest';
    _currentPage = 1;
    fetchBooks();
  }

  // Fetch books list
  Future<void> fetchBooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      try {
        _shelfStats = await _bookService.getShelfStats();
      } catch (_) {}
      try {
        _dashboardStats = await _bookService.getDashboardStats();
      } catch (_) {}

      final data = await _bookService.getBooks(
        search: _searchText,
        genre: _selectedGenre,
        rating: _selectedRating,
        shelf: _selectedShelf,
        sort: _sortOption,
        page: _currentPage,
        limit: _limit,
      );

      _books = data['books'] as List<Book>;
      final pagination = data['pagination'] as Map<String, dynamic>;
      _currentPage = pagination['page'] as int? ?? 1;
      _totalPages = pagination['totalPages'] as int? ?? 1;
      _totalBooks = pagination['totalBooks'] as int? ?? 0;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _books = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add Book
  Future<bool> addBook(Map<String, String> fields, String? coverPath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.addBook(fields, coverPath);
      await fetchBooks(); // Refresh list
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Edit Book
  Future<bool> editBook(int id, Map<String, String> fields, String? coverPath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.editBook(id, fields, coverPath);
      await fetchBooks(); // Refresh list
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete Book
  Future<bool> deleteBook(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.deleteBook(id);
      await fetchBooks(); // Refresh list
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Retrieve single book details directly from backend
  Future<Book?> getBookDetails(int id) async {
    try {
      return await _bookService.getBook(id);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }

  // Update shelf stats manually
  Future<void> fetchShelfStats() async {
    try {
      _shelfStats = await _bookService.getShelfStats();
      notifyListeners();
    } catch (_) {}
  }

  // Move book to another shelf
  Future<bool> updateBookShelf(int id, String shelf) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.updateBookShelf(id, shelf);
      await fetchBooks(); // Updates _books and calls getShelfStats internally
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update book reading page progress
  Future<bool> updateBookProgress(int id, int currentPage, int totalPages) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.updateBookProgress(id, currentPage, totalPages);
      await fetchBooks(); // Updates _books and refreshes stats
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Submit a rating and review for a completed book
  Future<bool> addReview(int id, String completionDate, int rating, String? review) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.addReview(id, completionDate, rating, review);
      await fetchBooks(); // Updates _books and refreshes stats
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch dashboard statistics manually
  Future<void> fetchDashboardStats() async {
    _isDashboardLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardStats = await _bookService.getDashboardStats();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  // Fetch all reading goals
  Future<void> fetchGoals() async {
    _isGoalsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _bookService.getGoals();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isGoalsLoading = false;
      notifyListeners();
    }
  }

  // Create an annual goal
  Future<bool> createGoal(int targetBooks, int year) async {
    _isGoalsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.createGoal(targetBooks, year);
      await fetchGoals(); // Refresh goals list
      await fetchDashboardStats(); // Keep dashboard statistics in sync
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isGoalsLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update target of existing goal
  Future<bool> updateGoal(int id, int targetBooks) async {
    _isGoalsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.updateGoal(id, targetBooks);
      await fetchGoals(); // Refresh goals list
      await fetchDashboardStats(); // Keep dashboard statistics in sync
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isGoalsLoading = false;
      notifyListeners();
      return false;
    }
  }
}
