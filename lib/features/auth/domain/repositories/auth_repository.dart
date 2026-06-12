import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<String?> getToken();
  Future<UserEntity?> getUser();
  Future<void> clearSession();
  Future<UserEntity> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  );
  Future<UserEntity> login(String email, String password);
  Future<void> logout();
  Future<String> requestPasswordReset(String email);
  Future<void> resetPassword(
    String token,
    String newPassword,
    String confirmPassword,
  );
}
