import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:book_collection/providers/book_provider.dart';
import 'package:book_collection/services/book_service.dart';
import 'package:book_collection/screens/reading_goals_screen.dart';

class MockBookService extends Fake implements BookService {
  bool getGoalsCalled = false;
  bool createGoalCalled = false;
  bool updateGoalCalled = false;
  bool shouldThrowError = false;
  String errorMessage = 'Error occurred';

  List<dynamic> mockGoals = [
    <String, dynamic>{
      'id': 1,
      'year': 2026,
      'targetBooks': 12,
      'completedBooks': 4,
      'progressPercentage': 33.3,
      'status': 'In Progress',
    },
    <String, dynamic>{
      'id': 2,
      'year': 2025,
      'targetBooks': 5,
      'completedBooks': 5,
      'progressPercentage': 100.0,
      'status': 'Achieved',
    }
  ];

  @override
  Future<List<dynamic>> getGoals() async {
    getGoalsCalled = true;
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    return mockGoals;
  }

  @override
  Future<Map<String, dynamic>> createGoal(int targetBooks, int year) async {
    createGoalCalled = true;
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    final newGoal = <String, dynamic>{
      'id': 3,
      'year': year,
      'targetBooks': targetBooks,
      'completedBooks': 0,
      'progressPercentage': 0.0,
      'status': 'Not Started',
    };
    mockGoals.add(newGoal);
    return newGoal;
  }

  @override
  Future<Map<String, dynamic>> updateGoal(int id, int targetBooks) async {
    updateGoalCalled = true;
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    for (var i = 0; i < mockGoals.length; i++) {
      if (mockGoals[i]['id'] == id) {
        mockGoals[i] = <String, dynamic>{
          'id': mockGoals[i]['id'],
          'year': mockGoals[i]['year'],
          'targetBooks': targetBooks,
          'completedBooks': mockGoals[i]['completedBooks'],
          'progressPercentage': (mockGoals[i]['completedBooks'] / targetBooks * 100).toDouble(),
          'status': mockGoals[i]['completedBooks'] >= targetBooks ? 'Achieved' : 'In Progress',
        };
        return mockGoals[i] as Map<String, dynamic>;
      }
    }
    throw Exception('Goal not found');
  }

  @override
  Future<Map<String, int>> getShelfStats() async {
    return {'wantToRead': 0, 'currentlyReading': 0, 'finishedReading': 0};
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
        home: ReadingGoalsScreen(bookProvider: bookProvider),
      ),
    );
  }

  group('ReadingGoalsScreen Widget Tests', () {
    testWidgets('renders empty state when goals list is empty', (WidgetTester tester) async {
      mockBookService.mockGoals = [];

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(mockBookService.getGoalsCalled, isTrue);
      expect(find.text('No Goals Configured'), findsOneWidget);
      expect(find.text('Set Your First Goal'), findsOneWidget);
    });

    testWidgets('renders goals list successfully', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(mockBookService.getGoalsCalled, isTrue);
      expect(find.text('2026 Reading Goal'), findsOneWidget);
      expect(find.text('4 of 12 books completed'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      expect(find.text('2025 Reading Goal'), findsOneWidget);
      expect(find.text('5 of 5 books completed'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Achieved'), findsOneWidget);
    });

    testWidgets('validates form fields during goal creation', (WidgetTester tester) async {
      mockBookService.mockGoals = [];

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      // Tap Set Your First Goal to open dialog
      await tester.tap(find.text('Set Your First Goal'));
      await tester.pumpAndSettle();

      expect(find.text('Create Reading Goal'), findsOneWidget);

      // Try saving empty fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Goal Year'), '');
      await tester.enterText(find.widgetWithText(TextFormField, 'Target Books'), '');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Please enter a year'), findsOneWidget);
      expect(find.text('Please enter target book count'), findsOneWidget);

      // Enter invalid year and negative target
      await tester.enterText(find.widgetWithText(TextFormField, 'Goal Year'), '99');
      await tester.enterText(find.widgetWithText(TextFormField, 'Target Books'), '-5');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Enter a valid year'), findsOneWidget);
      expect(find.text('Goal value must be greater than zero'), findsOneWidget);
    });

    testWidgets('creates a reading goal successfully', (WidgetTester tester) async {
      mockBookService.mockGoals = [];

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Set Your First Goal'));
      await tester.pumpAndSettle();

      // Enter valid details
      await tester.enterText(find.widgetWithText(TextFormField, 'Goal Year'), '2027');
      await tester.enterText(find.widgetWithText(TextFormField, 'Target Books'), '15');
      
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(mockBookService.createGoalCalled, isTrue);
      expect(find.text('Goal created successfully'), findsOneWidget);
    });

    testWidgets('edits an existing reading goal successfully', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      // Tap edit button on the first goal card
      final editIcon = find.byIcon(Icons.edit_outlined).first;
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      expect(find.text('Edit Goal Target'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // Pre-filled target count

      // Change target count
      await tester.enterText(find.widgetWithText(TextFormField, 'Target Books'), '16');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(mockBookService.updateGoalCalled, isTrue);
      expect(find.text('Goal updated successfully'), findsOneWidget);
    });
  });
}
