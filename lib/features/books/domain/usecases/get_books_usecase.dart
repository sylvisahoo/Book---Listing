import '../entities/book.dart';
import '../repositories/book_repository.dart';

class GetBooksUseCase {
  final BookRepository repository;

  GetBooksUseCase(this.repository);

  Future<Map<String, dynamic>> execute({
    String? search,
    String? genre,
    int? rating,
    String? shelf,
    String? sort,
    int page = 1,
    int limit = 10,
  }) async {
    return await repository.getBooks(
      search: search,
      genre: genre,
      rating: rating,
      shelf: shelf,
      sort: sort,
      page: page,
      limit: limit,
    );
  }
}
