import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:book_collection/providers/book_provider.dart';
import 'package:book_collection/services/book_service.dart';
import 'package:book_collection/screens/stats_dashboard_screen.dart';

class MockBookService extends Fake implements BookService {
  bool getDashboardStatsCalled = false;
  bool shouldThrowError = false;

  Map<String, dynamic> mockDashboardStats = {
    'collectionStats': {
      'totalBooks': 10,
      'totalBooksRead': 4,
      'currentlyReading': 2,
      'wantToRead': 6,
    },
    'readingStats': {
      'totalPagesRead': 1250,
      'completionRate': 40.0,
      'averageRating': 4.5,
    },
    'genreAnalysis': {
      'genreDistribution': [
        {'genre': 'Fiction', 'count': 5},
        {'genre': 'Technology', 'count': 3},
        {'genre': 'Biography', 'count': 1},
      ],
      'favoriteGenre': 'Fiction',
    },
    'readingInsights': {
      'readingStreak': 7,
      'booksFinishedThisMonth': 11,
      'booksFinishedThisYear': 8,
    },
    'readingGoal': {
      'id': 1,
      'year': 2026,
      'targetBooks': 12,
      'completedBooks': 9,
      'progressPercentage': 75.0,
      'status': 'In Progress',
    },
  };

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    getDashboardStatsCalled = true;
    if (shouldThrowError) {
      throw Exception('Failed to fetch dashboard stats');
    }
    return mockDashboardStats;
  }

  @override
  Future<Map<String, int>> getShelfStats() async {
    return {'wantToRead': 4, 'currentlyReading': 2, 'finishedReading': 4};
  }

  @override
  Future<Map<String, dynamic>> getBooks({
    String? search,
    String? genre,
    int? rating,
    String? shelf,
    String? sort,
    int page = 1,
    int limit = 10,
  }) async {
    return {
      'books': [],
      'pagination': {
        'page': 1,
        'limit': limit,
        'totalPages': 1,
        'totalBooks': 0,
      }
    };
  }
}

void main() {
  late MockBookService mockBookService;
  late BookProvider bookProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockBookService = MockBookService();
    bookProvider = BookProvider(bookService: mockBookService);
  });

  Widget buildTestableWidget() {
    return ChangeNotifierProvider<BookProvider>.value(
      value: bookProvider,
      child: MaterialApp(
        home: StatsDashboardScreen(bookProvider: bookProvider),
      ),
    );
  }

  group('StatsDashboardScreen Widget Tests', () {
    testWidgets('shows loading spinner when stats are loading and cache is null', (WidgetTester tester) async {
      // Set state to loading but keep stats null to trigger circular progress indicator
      await tester.pumpWidget(buildTestableWidget());
      
      // The screen automatically triggers fetchDashboardStats in initState's post frame callback.
      // So let's pump once to trigger init.
      await tester.pump();

      // Expect to see the loader
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows retry error screen when fetching fails', (WidgetTester tester) async {
      mockBookService.shouldThrowError = true;

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump(); // trigger initState callback
      await tester.pump(); // wait for fetchDashboardStats future to finish

      expect(mockBookService.getDashboardStatsCalled, isTrue);
      expect(find.text('No stats available'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders all aggregate metrics, streak, goals and genre analysis successfully', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump(); // trigger initState callback
      await tester.pump(); // wait for fetchDashboardStats future to finish

      expect(mockBookService.getDashboardStatsCalled, isTrue);

      // 1. Summary Cards verification
      expect(find.text('Total Books'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Reading Now'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Pages Read'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);

      // 2. Insights & Streaks verification
      expect(find.text('Activity Insights'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('11'), findsOneWidget); // finished this month
      expect(find.text('8'), findsOneWidget);  // finished this year

      // 3. Goal Card verification
      expect(find.text('2026 Reading Goal'), findsOneWidget);
      expect(find.text('9 of 12 books completed'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      // 4. Circular Progress & Avg Rating Gauges verification
      expect(find.text('Completion Rate'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Avg Rating'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);

      // 5. Favorite Genre verification
      expect(find.text('Favorite Genre'), findsOneWidget);
      expect(find.text('Fiction'), findsAtLeastNWidgets(2)); // Favorite genre banner & distribution list item

      // 6. Genre Distribution list verification
      expect(find.text('Genre Distribution'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('3 books'), findsOneWidget);
      expect(find.text('Biography'), findsOneWidget);
      expect(find.text('1 book'), findsOneWidget);
    });

    testWidgets('clicking retry triggers a new fetch request', (WidgetTester tester) async {
      mockBookService.shouldThrowError = true;

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(mockBookService.getDashboardStatsCalled, isTrue);
      mockBookService.getDashboardStatsCalled = false; // Reset checker

      // Tap Retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(mockBookService.getDashboardStatsCalled, isTrue);
    });
  });
}
