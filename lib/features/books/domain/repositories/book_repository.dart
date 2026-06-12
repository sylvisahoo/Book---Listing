import '../entities/book.dart';

abstract class BookRepository {
  Future<Map<String, dynamic>> getBooks({
    String? search,
    String? genre,
    int? rating,
    String? shelf,
    String? sort,
    int page = 1,
    int limit = 10,
  });

  Future<Book> getBook(int id);

  Future<Book> addBook(Map<String, String> fields, String? coverPath);

  Future<Book> editBook(int id, Map<String, String> fields, String? coverPath);

  Future<void> deleteBook(int id);

  Future<Book> updateBookShelf(int id, String shelf);

  Future<Book> updateBookProgress(int id, int currentPage, int totalPages);

  Future<Map<String, int>> getShelfStats();

  Future<Book> addReview(
    int id,
    String completionDate,
    int rating,
    String? review,
  );

  Future<Map<String, dynamic>> getDashboardStats();

  Future<List<dynamic>> getGoals();

  Future<Map<String, dynamic>> createGoal(int targetBooks, int year);

  Future<Map<String, dynamic>> updateGoal(int id, int targetBooks);
}
