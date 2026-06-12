import '../entities/book.dart';
import '../repositories/book_repository.dart';

class AddReviewUseCase {
  final BookRepository repository;

  AddReviewUseCase(this.repository);

  Future<Book> execute(
    int id,
    String completionDate,
    int rating,
    String? review,
  ) async {
    return await repository.addReview(id, completionDate, rating, review);
  }
}
