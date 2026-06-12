import '../repositories/book_repository.dart';

class CreateGoalUseCase {
  final BookRepository repository;

  CreateGoalUseCase(this.repository);

  Future<Map<String, dynamic>> execute(int targetBooks, int year) async {
    return await repository.createGoal(targetBooks, year);
  }
}
