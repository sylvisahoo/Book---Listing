import '../repositories/book_repository.dart';

class GetDashboardStatsUseCase {
  final BookRepository repository;

  GetDashboardStatsUseCase(this.repository);

  Future<Map<String, dynamic>> execute() async {
    return await repository.getDashboardStats();
  }
}
