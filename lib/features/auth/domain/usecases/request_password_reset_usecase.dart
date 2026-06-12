import '../repositories/auth_repository.dart';

class RequestPasswordResetUseCase {
  final AuthRepository repository;

  RequestPasswordResetUseCase(this.repository);

  Future<String> execute(String email) async {
    return await repository.requestPasswordReset(email);
  }
}
