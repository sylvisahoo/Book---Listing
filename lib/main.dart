import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_request_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/books/presentation/screens/home_screen.dart';
import 'features/books/presentation/screens/book_list_screen.dart';
import 'features/books/presentation/screens/book_detail_screen.dart';
import 'features/books/presentation/screens/add_edit_book_screen.dart';
import 'features/books/presentation/screens/stats_dashboard_screen.dart';
import 'features/books/presentation/screens/reading_goals_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      title: 'Bookly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFF6F91),
        scaffoldBackgroundColor: const Color(0xFFFFF5F1),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF6F91),
          onPrimary: Color(0xFF4A2B33),
          secondary: Color(0xFFFFC2D1),
          onSecondary: Color(0xFF4A2B33),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF4A2B33),
          error: Color(0xFFE85D75),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Outfit',
          bodyColor: const Color(0xFF4A2B33),
          displayColor: const Color(0xFF4A2B33),
        ),
      ),
      home: authState.isLoading
          ? const Scaffold(
              backgroundColor: Color(0xFFFFF5F1),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6F91),
                ),
              ),
            )
          : authState.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/reset-request': (context) => const ResetRequestScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/books': (context) => const BookListScreen(),
        '/book-detail': (context) => const BookDetailScreen(),
        '/add-edit-book': (context) => const AddEditBookScreen(),
        '/stats-dashboard': (context) => const StatsDashboardScreen(),
        '/goals': (context) => const ReadingGoalsScreen(),
      },
    );
  }
}
