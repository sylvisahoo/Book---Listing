import '../repositories/book_repository.dart';

class GetShelfStatsUseCase {
  final BookRepository repository;

  GetShelfStatsUseCase(this.repository);

  Future<Map<String, int>> execute() async {
    return await repository.getShelfStats();
  }
}
