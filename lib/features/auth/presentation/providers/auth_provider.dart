import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

// Dependency Injection Providers
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    localDataSource: ref.watch(authLocalDataSourceProvider),
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>((ref) {
  return CheckAuthStatusUseCase(ref.watch(authRepositoryProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final requestPasswordResetUseCaseProvider = Provider<RequestPasswordResetUseCase>((ref) {
  return RequestPasswordResetUseCase(ref.watch(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});

// State definition
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserEntity? currentUser;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.currentUser,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserEntity? currentUser,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// StateNotifier definition
class AuthNotifier extends StateNotifier<AuthState> {
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final RequestPasswordResetUseCase _requestPasswordResetUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  AuthNotifier({
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required RequestPasswordResetUseCase requestPasswordResetUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  })  : _checkAuthStatusUseCase = checkAuthStatusUseCase,
        _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _requestPasswordResetUseCase = requestPasswordResetUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        super(AuthState()) {
    checkAuthStatus();
  }

  // Clear errors
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Check stored credentials on start
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _checkAuthStatusUseCase.execute();
      state = state.copyWith(
        currentUser: user,
        isAuthenticated: user != null,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isAuthenticated: false,
        clearUser: true,
        isLoading: false,
      );
    }
  }

  // Perform login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _loginUseCase.execute(email, password);
      state = state.copyWith(
        currentUser: user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        errorMessage: errorMsg,
        isAuthenticated: false,
        clearUser: true,
        isLoading: false,
      );
      return false;
    }
  }

  // Perform registration
  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _registerUseCase.execute(
        name,
        email,
        password,
        confirmPassword,
      );
      state = state.copyWith(
        currentUser: user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        errorMessage: errorMsg,
        isAuthenticated: false,
        clearUser: true,
        isLoading: false,
      );
      return false;
    }
  }

  // Perform logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _logoutUseCase.execute();
    } catch (_) {
    } finally {
      state = state.copyWith(
        clearUser: true,
        isAuthenticated: false,
        isLoading: false,
      );
    }
  }

  // Request password reset token
  Future<String?> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _requestPasswordResetUseCase.execute(email);
      state = state.copyWith(isLoading: false);
      return token;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        errorMessage: errorMsg,
        isLoading: false,
      );
      return null;
    }
  }

  // Execute password reset
  Future<bool> resetPassword(
    String token,
    String newPassword,
    String confirmPassword,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _resetPasswordUseCase.execute(token, newPassword, confirmPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        errorMessage: errorMsg,
        isLoading: false,
      );
      return false;
    }
  }
}

// Global Provider Exposing Auth State and Controller
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    checkAuthStatusUseCase: ref.watch(checkAuthStatusUseCaseProvider),
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    requestPasswordResetUseCase: ref.watch(requestPasswordResetUseCaseProvider),
    resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
  );
});
