import '../entities/book.dart';
import '../repositories/book_repository.dart';

class UpdateBookProgressUseCase {
  final BookRepository repository;

  UpdateBookProgressUseCase(this.repository);

  Future<Book> execute(int id, int currentPage, int totalPages) async {
    return await repository.updateBookProgress(id, currentPage, totalPages);
  }
}
