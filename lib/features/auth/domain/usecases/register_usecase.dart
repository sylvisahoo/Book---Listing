import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<UserEntity> execute(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    return await repository.register(name, email, password, confirmPassword);
  }
}
