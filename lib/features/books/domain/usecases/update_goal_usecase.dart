import '../repositories/book_repository.dart';

class UpdateGoalUseCase {
  final BookRepository repository;

  UpdateGoalUseCase(this.repository);

  Future<Map<String, dynamic>> execute(int id, int targetBooks) async {
    return await repository.updateGoal(id, targetBooks);
  }
}
