import '../repositories/book_repository.dart';

class GetGoalsUseCase {
  final BookRepository repository;

  GetGoalsUseCase(this.repository);

  Future<List<dynamic>> execute() async {
    return await repository.getGoals();
  }
}
