import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_collection/features/books/domain/entities/book.dart';
import 'package:book_collection/features/books/domain/repositories/book_repository.dart';
import 'package:book_collection/features/books/presentation/providers/book_provider.dart';
import 'package:book_collection/features/books/presentation/screens/book_list_screen.dart';
import 'package:book_collection/features/books/presentation/screens/add_edit_book_screen.dart';

class MockBookRepository extends Fake implements BookRepository {
  bool getBooksCalled = false;
  bool addBookCalled = false;
  bool shouldThrowError = false;
  String errorMessage = 'Error occurred';

  int requestedPage = 1;
  int requestedLimit = 6;

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
    requestedPage = page;
    requestedLimit = limit;

    return {
      'books': [
        Book(
          id: 1,
          userId: 1,
          title: 'Clean Code',
          author: 'Robert C. Martin',
          genre: 'Software Engineering',
          publicationYear: 2008,
          shelf: 'Finished Reading',
          currentPage: 300,
          totalPages: 300,
        )
      ],
      'pagination': {
        'page': page,
        'limit': limit,
        'totalPages': 3,
        'totalBooks': 15,
      }
    };
  }

  @override
  Future<Book> addBook(Map<String, String> fields, String? coverPath) async {
    addBookCalled = true;
    if (shouldThrowError) {
      throw Exception(errorMessage);
    }
    return Book(
      id: 1,
      userId: 1,
      title: fields['title'] ?? 'Title',
      author: fields['author'] ?? 'Author',
      genre: fields['genre'] ?? 'Genre',
      publicationYear: int.parse(fields['publication_year'] ?? '2020'),
      shelf: fields['shelf'] ?? 'Want To Read',
      currentPage: 0,
      totalPages: 0,
    );
  }

  @override
  Future<Map<String, int>> getShelfStats() async {
    return {'wantToRead': 0, 'currentlyReading': 0, 'finishedReading': 0};
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
      ),
    );
  }

  group('BookListScreen Pagination Widget Tests', () {
    testWidgets('renders current page status and paginates correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const BookListScreen()));
      await tester.pump();
      await tester.pump();

      expect(mockBookRepository.getBooksCalled, isTrue);
      // Defaults to page 1 of 3
      expect(find.text('Page 1 of 3'), findsOneWidget);

      // Tap Next Page button (arrow_forward_ios icon button)
      final nextButton = find.widgetWithIcon(IconButton, Icons.arrow_forward_ios);
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(mockBookRepository.requestedPage, toBe(2));

      // Now page should be 2. Let's manually set page to 2 and rebuild to ensure previous button works
      final element = tester.element(find.byType(BookListScreen));
      final container = ProviderScope.containerOf(element);
      container.read(bookNotifierProvider.notifier).setPage(2);
      
      await tester.pumpAndSettle();
      expect(find.text('Page 2 of 3'), findsOneWidget);

      // Tap Previous Page button (arrow_back_ios icon button)
      final prevButton = find.widgetWithIcon(IconButton, Icons.arrow_back_ios);
      expect(prevButton, findsOneWidget);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      expect(mockBookRepository.requestedPage, toBe(1));
    });
  });

  group('AddEditBookScreen DB Constraint Error Dialog Tests', () {
    testWidgets('displays error dialog when DB constraint violation occurs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockBookRepository.shouldThrowError = true;
      mockBookRepository.errorMessage = '23503: Foreign key violation';

      await tester.pumpWidget(buildTestableWidget(const AddEditBookScreen()));
      await tester.pump();

      // Enter valid fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Book Title'), 'Invalid User Book');
      await tester.enterText(find.widgetWithText(TextFormField, 'Author'), 'Author');
      await tester.enterText(find.widgetWithText(TextFormField, 'Genre'), 'Genre');
      await tester.enterText(find.widgetWithText(TextFormField, 'Publication Year'), '2020');

      // Tap Save Book
      await tester.tap(find.text('Save Book'));
      await tester.pumpAndSettle();

      expect(mockBookRepository.addBookCalled, isTrue);

      // Verify that error alert dialog appears with the exception message
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('23503: Foreign key violation'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });
}

Matcher toBe(int expected) => equals(expected);
