import '../entities/book.dart';
import '../repositories/book_repository.dart';

class GetBookDetailsUseCase {
  final BookRepository repository;

  GetBookDetailsUseCase(this.repository);

  Future<Book> execute(int id) async {
    return await repository.getBook(id);
  }
}
