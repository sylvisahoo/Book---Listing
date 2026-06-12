import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_collection/features/books/domain/entities/book.dart';
import 'package:book_collection/features/books/domain/repositories/book_repository.dart';
import 'package:book_collection/features/books/presentation/providers/book_provider.dart';
import 'package:book_collection/features/books/presentation/screens/book_list_screen.dart';
import 'package:book_collection/features/books/presentation/screens/book_detail_screen.dart';

class MockBookRepository extends Fake implements BookRepository {
  bool getBooksCalled = false;
  bool getBookCalled = false;
  bool updateShelfCalled = false;
  bool getShelfStatsCalled = false;

  Map<String, int> mockShelfStats = {
    'wantToRead': 3,
    'currentlyReading': 2,
    'finishedReading': 5,
  };

  Book mockBook = Book(
    id: 101,
    userId: 1,
    title: 'Design Patterns',
    author: 'Gang of Four',
    genre: 'Software Engineering',
    publicationYear: 1994,
    shelf: 'Want To Read',
    currentPage: 0,
    totalPages: 0,
  );

  @override
  Future<Map<String, int>> getShelfStats() async {
    getShelfStatsCalled = true;
    return mockShelfStats;
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
    getBooksCalled = true;
    return {
      'books': [mockBook],
      'pagination': {
        'page': 1,
        'limit': limit,
        'totalPages': 1,
        'totalBooks': 1,
      }
    };
  }

  @override
  Future<Book> getBook(int id) async {
    getBookCalled = true;
    return mockBook;
  }

  @override
  Future<Book> updateBookShelf(int id, String shelf) async {
    updateShelfCalled = true;
    mockBook = Book(
      id: mockBook.id,
      userId: mockBook.userId,
      title: mockBook.title,
      author: mockBook.author,
      genre: mockBook.genre,
      publicationYear: mockBook.publicationYear,
      shelf: shelf,
      currentPage: mockBook.currentPage,
      totalPages: mockBook.totalPages,
    );
    return mockBook;
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    return {};
  }
}

void main() {
  late MockBookRepository mockBookRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockBookRepository = MockBookRepository();
  });

  Widget buildTestableWidget(Widget screen) {
    return ProviderScope(
      overrides: [
        bookRepositoryProvider.overrideWithValue(mockBookRepository),
      ],
      child: MaterialApp(
        home: screen,
        routes: {
          '/book-detail': (context) => const BookDetailScreen(),
        },
      ),
    );
  }

  group('BookListScreen Shelf Stats Header Tests', () {
    testWidgets('renders shelf statistics counts correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const BookListScreen()));
      await tester.pump(); // trigger initState post frame callbacks
      await tester.pump(); // wait for async calls to finish

      expect(mockBookRepository.getShelfStatsCalled, isTrue);
      expect(mockBookRepository.getBooksCalled, isTrue);

      // Verify that shelf stats counts from mock shelf stats are displayed
      expect(find.text('3'), findsOneWidget); // Want to Read count
      expect(find.text('2'), findsOneWidget); // Reading count
      expect(find.text('5'), findsOneWidget); // Finished count

      expect(find.text('Want to Read'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
    });
  });

  group('BookDetailScreen Shelf Interaction Tests', () {
    testWidgets('displays current shelf tag and tapping opens bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookRepositoryProvider.overrideWithValue(mockBookRepository),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/book-detail', arguments: 101);
                  },
                  child: const Text('Go to details'),
                );
              },
            ),
            routes: {
              '/book-detail': (context) => const BookDetailScreen(),
            },
          ),
        ),
      );

      // Tap button to go to details screen
      await tester.tap(find.text('Go to details'));
      await tester.pumpAndSettle();

      expect(mockBookRepository.getBookCalled, isTrue);
      expect(find.text('Design Patterns'), findsOneWidget);
      expect(find.text('Want To Read'), findsOneWidget); // current shelf display

      // Tap on the shelf status tag chip/button to open change shelf bottom sheet
      await tester.tap(find.text('Want To Read'));
      await tester.pumpAndSettle();

      // Bottom sheet should open displaying shelf options
      expect(find.text('Move to Shelf'), findsOneWidget);
      expect(find.text('Currently Reading'), findsOneWidget);
      expect(find.text('Finished Reading'), findsOneWidget);
    });

    testWidgets('moving to Currently Reading shelf updates status', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookRepositoryProvider.overrideWithValue(mockBookRepository),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/book-detail', arguments: 101);
                  },
                  child: const Text('Go to details'),
                );
              },
            ),
            routes: {
              '/book-detail': (context) => const BookDetailScreen(),
            },
          ),
        ),
      );

      await tester.tap(find.text('Go to details'));
      await tester.pumpAndSettle();

      // Tap shelf tag to open bottom sheet
      await tester.tap(find.text('Want To Read'));
      await tester.pumpAndSettle();

      // Select Currently Reading option
      await tester.tap(find.text('Currently Reading'));
      await tester.pumpAndSettle();

      expect(mockBookRepository.updateShelfCalled, isTrue);
    });
  });
}
