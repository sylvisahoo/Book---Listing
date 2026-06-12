import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<String?> getToken() => localDataSource.getToken();

  @override
  Future<UserEntity?> getUser() => localDataSource.getUser();

  @override
  Future<void> clearSession() => localDataSource.clearSession();

  @override
  Future<UserEntity> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    final result = await remoteDataSource.register(
      name,
      email,
      password,
      confirmPassword,
    );
    final token = result['token'] as String;
    final user = result['user'] as UserEntity;
    await localDataSource.saveSession(token, user);
    return user;
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    final result = await remoteDataSource.login(email, password);
    final token = result['token'] as String;
    final user = result['user'] as UserEntity;
    await localDataSource.saveSession(token, user);
    return user;
  }

  @override
  Future<void> logout() async {
    final token = await localDataSource.getToken();
    if (token != null) {
      try {
        await remoteDataSource.logout(token);
      } catch (_) {
        // Clear locally even if remote call fails
      }
    }
    await localDataSource.clearSession();
  }

  @override
  Future<String> requestPasswordReset(String email) {
    return remoteDataSource.requestPasswordReset(email);
  }

  @override
  Future<void> resetPassword(
    String token,
    String newPassword,
    String confirmPassword,
  ) {
    return remoteDataSource.resetPassword(token, newPassword, confirmPassword);
  }
}
