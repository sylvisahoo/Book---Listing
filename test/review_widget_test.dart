import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_collection/features/books/domain/entities/book.dart';
import 'package:book_collection/features/books/domain/repositories/book_repository.dart';
import 'package:book_collection/features/books/presentation/providers/book_provider.dart';
import 'package:book_collection/features/books/presentation/screens/book_detail_screen.dart';

class MockBookRepository extends Fake implements BookRepository {
  bool getBookCalled = false;
  bool addReviewCalled = false;
  
  Book mockBook = Book(
    id: 101,
    userId: 1,
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    genre: 'Fiction',
    publicationYear: 1925,
    shelf: 'Finished Reading',
    currentPage: 0,
    totalPages: 0,
    completionDate: '2026-06-01',
    rating: 4,
    review: 'An absolute masterpiece.',
  );

  @override
  Future<Book> getBook(int id) async {
    getBookCalled = true;
    return mockBook;
  }

  @override
  Future<Book> addReview(
    int id,
    String completionDate,
    int rating,
    String? review,
  ) async {
    addReviewCalled = true;
    mockBook = Book(
      id: mockBook.id,
      userId: mockBook.userId,
      title: mockBook.title,
      author: mockBook.author,
      genre: mockBook.genre,
      publicationYear: mockBook.publicationYear,
      shelf: 'Finished Reading',
      currentPage: mockBook.currentPage,
      totalPages: mockBook.totalPages,
      completionDate: completionDate,
      rating: rating,
      review: review,
    );
    return mockBook;
  }

  @override
  Future<Map<String, int>> getShelfStats() async {
    return {'wantToRead': 0, 'currentlyReading': 0, 'finishedReading': 1};
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    return {};
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
    return {'books': [mockBook], 'pagination': {'page': 1, 'limit': limit, 'totalPages': 1, 'totalBooks': 1}};
  }
}

void main() {
  late MockBookRepository mockBookRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockBookRepository = MockBookRepository();
  });

  Widget buildTestableWidget() {
    return ProviderScope(
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
    );
  }

  group('BookDetailScreen Ratings & Reviews Tests', () {
    testWidgets('renders review display elements correctly for finished books', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      
      await tester.tap(find.text('Go to details'));
      await tester.pumpAndSettle();

      expect(mockBookRepository.getBookCalled, isTrue);
      expect(find.text('The Great Gatsby'), findsOneWidget);
      expect(find.text('Your Rating & Review'), findsOneWidget);
      expect(find.text('Completed: 2026-06-01'), findsOneWidget);
      expect(find.text('An absolute masterpiece.'), findsOneWidget);
    });

    testWidgets('shows alternative text when review is empty or null', (WidgetTester tester) async {
      mockBookRepository.mockBook = Book(
        id: 101,
        userId: 1,
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        genre: 'Fiction',
        publicationYear: 1925,
        shelf: 'Finished Reading',
        currentPage: 0,
        totalPages: 0,
        completionDate: '2026-06-01',
        rating: 4,
        review: null,
      );

      await tester.pumpWidget(buildTestableWidget());
      
      await tester.tap(find.text('Go to details'));
      await tester.pumpAndSettle();

      expect(find.text('No written review provided.'), findsOneWidget);
    });

    testWidgets('edit review button opens dialog and submits successfully', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      
      await tester.tap(find.text('Go to details'));
      await tester.pumpAndSettle();

      // Tap the edit review icon button
      final reviewRow = find.ancestor(
        of: find.text('Your Rating & Review'),
        matching: find.byType(Row),
      );
      final editButton = find.descendant(
        of: reviewRow,
        matching: find.byType(IconButton),
      );
      await tester.scrollUntilVisible(editButton, 50.0);
      await tester.pumpAndSettle();
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Check dialog header
      expect(find.text('Edit Review & Rating'), findsOneWidget);

      // Verify the text field has existing review prefilled
      expect(find.text('An absolute masterpiece.'), findsAtLeastNWidgets(2)); // Display page + Dialog Field

      // Tap 5th star to change rating to 5
      final starButtons = find.byIcon(Icons.star);
      // There are 5 stars on details screen + 5 stars inside the dialog. Let's tap the 10th star (5th star in the dialog).
      await tester.tap(starButtons.at(9));
      await tester.pump();

      // Enter new review text
      await tester.enterText(find.widgetWithText(TextFormField, 'Written Review (optional)'), 'Truly an incredible read!');

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(mockBookRepository.addReviewCalled, isTrue);
    });
  });
}
