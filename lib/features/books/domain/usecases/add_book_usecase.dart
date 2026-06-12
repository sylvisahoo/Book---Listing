import '../entities/book.dart';
import '../repositories/book_repository.dart';

class AddBookUseCase {
  final BookRepository repository;

  AddBookUseCase(this.repository);

  Future<Book> execute(Map<String, String> fields, String? coverPath) async {
    return await repository.addBook(fields, coverPath);
  }
}
