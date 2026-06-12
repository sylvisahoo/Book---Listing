import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<void> execute(
    String token,
    String newPassword,
    String confirmPassword,
  ) async {
    await repository.resetPassword(token, newPassword, confirmPassword);
  }
}
