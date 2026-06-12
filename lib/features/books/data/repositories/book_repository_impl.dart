import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_data_source.dart';

class BookRepositoryImpl implements BookRepository {
  final BookRemoteDataSource remoteDataSource;

  BookRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> getBooks({
    String? search,
    String? genre,
    int? rating,
    String? shelf,
    String? sort,
    int page = 1,
    int limit = 10,
  }) {
    return remoteDataSource.getBooks(
      search: search,
      genre: genre,
      rating: rating,
      shelf: shelf,
      sort: sort,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Book> getBook(int id) => remoteDataSource.getBook(id);

  @override
  Future<Book> addBook(Map<String, String> fields, String? coverPath) {
    return remoteDataSource.addBook(fields, coverPath);
  }

  @override
  Future<Book> editBook(int id, Map<String, String> fields, String? coverPath) {
    return remoteDataSource.editBook(id, fields, coverPath);
  }

  @override
  Future<void> deleteBook(int id) => remoteDataSource.deleteBook(id);

  @override
  Future<Book> updateBookShelf(int id, String shelf) {
    return remoteDataSource.updateBookShelf(id, shelf);
  }

  @override
  Future<Book> updateBookProgress(int id, int currentPage, int totalPages) {
    return remoteDataSource.updateBookProgress(id, currentPage, totalPages);
  }

  @override
  Future<Map<String, int>> getShelfStats() => remoteDataSource.getShelfStats();

  @override
  Future<Book> addReview(
    int id,
    String completionDate,
    int rating,
    String? review,
  ) {
    return remoteDataSource.addReview(id, completionDate, rating, review);
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() {
    return remoteDataSource.getDashboardStats();
  }

  @override
  Future<List<dynamic>> getGoals() => remoteDataSource.getGoals();

  @override
  Future<Map<String, dynamic>> createGoal(int targetBooks, int year) {
    return remoteDataSource.createGoal(targetBooks, year);
  }

  @override
  Future<Map<String, dynamic>> updateGoal(int id, int targetBooks) {
    return remoteDataSource.updateGoal(id, targetBooks);
  }
}
