import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  Future<UserEntity?> execute() async {
    final token = await repository.getToken();
    if (token != null) {
      return await repository.getUser();
    }
    return null;
  }
}
