import '../entities/book.dart';
import '../repositories/book_repository.dart';

class EditBookUseCase {
  final BookRepository repository;

  EditBookUseCase(this.repository);

  Future<Book> execute(
    int id,
    Map<String, String> fields,
    String? coverPath,
  ) async {
    return await repository.editBook(id, fields, coverPath);
  }
}
