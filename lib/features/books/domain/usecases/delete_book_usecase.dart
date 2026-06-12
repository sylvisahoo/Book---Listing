import '../repositories/book_repository.dart';

class DeleteBookUseCase {
  final BookRepository repository;

  DeleteBookUseCase(this.repository);

  Future<void> execute(int id) async {
    await repository.deleteBook(id);
  }
}
