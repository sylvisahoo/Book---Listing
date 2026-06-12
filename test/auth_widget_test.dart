import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_collection/features/auth/domain/entities/user_entity.dart';
import 'package:book_collection/features/auth/domain/repositories/auth_repository.dart';
import 'package:book_collection/features/auth/presentation/providers/auth_provider.dart';
import 'package:book_collection/features/auth/presentation/screens/login_screen.dart';
import 'package:book_collection/features/auth/presentation/screens/register_screen.dart';
import 'package:book_collection/features/auth/presentation/screens/reset_request_screen.dart';
import 'package:book_collection/features/auth/presentation/screens/reset_password_screen.dart';

class MockAuthRepository extends Fake implements AuthRepository {
  bool registerCalled = false;
  bool loginCalled = false;
  bool logoutCalled = false;
  bool requestResetCalled = false;
  bool resetPasswordCalled = false;
  bool clearSessionCalled = false;

  String? mockToken = 'mock_jwt_token';
  UserEntity? mockUser = const UserEntity(
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
  );

  String? tokenToReturn;
  UserEntity? userToReturn;

  bool shouldThrowError = false;
  String errorMessage = 'Error occurred';

  @override
  Future<String?> getToken() async => tokenToReturn;

  @override
  Future<UserEntity?> getUser() async => userToReturn;

  @override
  Future<void> clearSession() async {
    clearSessionCalled = true;
    tokenToReturn = null;
    userToReturn = null;
  }

  @override
  Future<UserEntity> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    registerCalled = true;
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    tokenToReturn = mockToken;
    userToReturn = mockUser;
    return mockUser!;
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    loginCalled = true;
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    tokenToReturn = mockToken;
    userToReturn = mockUser;
    return mockUser!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    await clearSession();
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    requestResetCalled = true;
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    return 'mock_reset_token';
  }

  @override
  Future<void> resetPassword(
    String token,
    String newPassword,
    String confirmPassword,
  ) async {
    resetPasswordCalled = true;
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
  }
}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepository = MockAuthRepository();
  });

  Widget buildTestableWidget(Widget screen) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: MaterialApp(
        home: screen,
        routes: {
          '/register': (context) => const RegisterScreen(),
          '/reset-request': (context) => const ResetRequestScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
        },
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('displays login fields and title', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pump();

      expect(find.text('Sign In'), findsAtLeastNWidgets(2)); // Title and Button text
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pump();

      // Tap Sign In button without entering any values
      final signInButton = find.byType(ElevatedButton);
      await tester.tap(signInButton);
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pump();

      // Enter invalid email and pass
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'invalid-email');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      
      final signInButton = find.byType(ElevatedButton);
      await tester.tap(signInButton);
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('successful login navigates or triggers logic', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'john@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');

      final signInButton = find.byType(ElevatedButton);
      await tester.tap(signInButton);
      await tester.pump();

      expect(mockAuthRepository.loginCalled, isTrue);
    });

    testWidgets('failed login shows failure dialog', (WidgetTester tester) async {
      mockAuthRepository.shouldThrowError = true;
      mockAuthRepository.errorMessage = 'Invalid email or password';

      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'john@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'wrongpassword');

      final signInButton = find.byType(ElevatedButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(mockAuthRepository.loginCalled, isTrue);
      expect(find.text('Login Failed'), findsOneWidget);
      expect(find.text('Invalid email or password'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('shows validation errors for empty values', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const RegisterScreen()));
      await tester.pump();

      final signUpButton = find.byType(ElevatedButton);
      await tester.tap(signUpButton);
      await tester.pump();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('shows validation error for short password', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const RegisterScreen()));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'john@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), '123');

      final signUpButton = find.byType(ElevatedButton);
      await tester.tap(signUpButton);
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('shows validation error for mismatched passwords', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const RegisterScreen()));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'john@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'password456');

      final signUpButton = find.byType(ElevatedButton);
      await tester.tap(signUpButton);
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('successful registration triggers registration API', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const RegisterScreen()));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'john@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'password123');

      final signUpButton = find.byType(ElevatedButton);
      await tester.tap(signUpButton);
      await tester.pump();

      expect(mockAuthRepository.registerCalled, isTrue);
    });
  });

  group('ResetRequestScreen & ResetPasswordScreen Tests', () {
    testWidgets('Forgot password workflow and generated token dialog', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const ResetRequestScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'john@example.com');
      
      final requestButton = find.byType(ElevatedButton);
      await tester.tap(requestButton);
      await tester.pumpAndSettle();

      expect(mockAuthRepository.requestResetCalled, isTrue);
      expect(find.text('Reset Token Generated!'), findsOneWidget);
      expect(find.text('mock_reset_token'), findsOneWidget);
    });

    testWidgets('Reset Password with token updates password successfully', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const ResetPasswordScreen()));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Reset Token'), 'mock_reset_token');
      await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'newpassword123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'newpassword123');

      final resetButton = find.byType(ElevatedButton);
      await tester.tap(resetButton);
      await tester.pump();

      expect(mockAuthRepository.resetPasswordCalled, isTrue);
    });
  });
}
