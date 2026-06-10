import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_request_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/add_edit_book_screen.dart';
import 'screens/stats_dashboard_screen.dart';
import 'screens/reading_goals_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final bookProvider = Provider.of<BookProvider>(
            context,
            listen: false,
          );
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
            home: authProvider.isLoading
                ? const Scaffold(
                    backgroundColor: Color(0xFFFFF5F1),
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6F91),
                      ),
                    ),
                  )
                : authProvider.isAuthenticated
                ? HomeScreen(authProvider: authProvider)
                : LoginScreen(authProvider: authProvider),
            routes: {
              '/register': (context) =>
                  RegisterScreen(authProvider: authProvider),
              '/reset-request': (context) =>
                  ResetRequestScreen(authProvider: authProvider),
              '/reset-password': (context) =>
                  ResetPasswordScreen(authProvider: authProvider),
              '/books': (context) => BookListScreen(bookProvider: bookProvider),
              '/book-detail': (context) =>
                  BookDetailScreen(bookProvider: bookProvider),
              '/add-edit-book': (context) =>
                  AddEditBookScreen(bookProvider: bookProvider),
              '/stats-dashboard': (context) =>
                  StatsDashboardScreen(bookProvider: bookProvider),
              '/goals': (context) =>
                  ReadingGoalsScreen(bookProvider: bookProvider),
            },
          );
        },
      ),
    );
  }
}
