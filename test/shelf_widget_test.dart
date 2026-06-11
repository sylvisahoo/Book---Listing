import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:book_collection/providers/book_provider.dart';
import 'package:book_collection/services/book_service.dart';
import 'package:book_collection/models/book.dart';
import 'package:book_collection/screens/book_list_screen.dart';
import 'package:book_collection/screens/book_detail_screen.dart';

class MockBookService extends Fake implements BookService {
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
  late MockBookService mockBookService;
  late BookProvider bookProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockBookService = MockBookService();
    bookProvider = BookProvider(bookService: mockBookService);
  });

  Widget buildTestableWidget(Widget screen) {
    return ChangeNotifierProvider<BookProvider>.value(
      value: bookProvider,
      child: MaterialApp(
        home: screen,
        routes: {
          '/book-detail': (context) => BookDetailScreen(bookProvider: bookProvider),
        },
      ),
    );
  }

  group('BookListScreen Shelf Stats Header Tests', () {
    testWidgets('renders shelf statistics counts correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(BookListScreen(bookProvider: bookProvider)));
      await tester.pump(); // trigger initState post frame callbacks
      await tester.pump(); // wait for async calls to finish

      expect(mockBookService.getShelfStatsCalled, isTrue);
      expect(mockBookService.getBooksCalled, isTrue);

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
      // Setup routing with argument for Book ID 101
      await tester.pumpWidget(
        ChangeNotifierProvider<BookProvider>.value(
          value: bookProvider,
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
              '/book-detail': (context) => BookDetailScreen(bookProvider: bookProvider),
            },
          ),
        ),
      );

      // Tap button to go to details screen
      await tester.tap(find.text('Go to details'));
      await tester.pumpAndSettle();

      expect(mockBookService.getBookCalled, isTrue);
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
        ChangeNotifierProvider<BookProvider>.value(
          value: bookProvider,
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
              '/book-detail': (context) => BookDetailScreen(bookProvider: bookProvider),
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

      expect(mockBookService.updateShelfCalled, isTrue);
    });
  });
}
