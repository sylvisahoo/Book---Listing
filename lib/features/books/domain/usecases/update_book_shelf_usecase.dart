import '../entities/book.dart';
import '../repositories/book_repository.dart';

class UpdateBookShelfUseCase {
  final BookRepository repository;

  UpdateBookShelfUseCase(this.repository);

  Future<Book> execute(int id, String shelf) async {
    return await repository.updateBookShelf(id, shelf);
  }
}
