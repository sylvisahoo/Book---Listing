import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_collection/features/books/domain/entities/book.dart';
import 'package:book_collection/features/books/domain/repositories/book_repository.dart';
import 'package:book_collection/features/books/presentation/providers/book_provider.dart';
import 'package:book_collection/features/books/presentation/screens/book_list_screen.dart';

class MockBookRepository extends Fake implements BookRepository {
  bool getBooksCalled = false;
  String? lastSearch;
  String? lastGenre;
  int? lastRating;
  String? lastShelf;
  String? lastSort;

  List<Book> mockBooksList = [
    Book(
      id: 101,
      userId: 1,
      title: 'Clean Code',
      author: 'Robert C. Martin',
      genre: 'Software Engineering',
      publicationYear: 2008,
      shelf: 'Finished Reading',
      currentPage: 460,
      totalPages: 460,
      rating: 5,
    ),
    Book(
      id: 102,
      userId: 1,
      title: 'Design Patterns',
      author: 'Erich Gamma',
      genre: 'Technology',
      publicationYear: 1994,
      shelf: 'Want To Read',
      currentPage: 0,
      totalPages: 0,
      rating: 4,
    )
  ];

  @override
  Future<Map<String, int>> getShelfStats() async {
    return {'wantToRead': 1, 'currentlyReading': 0, 'finishedReading': 1};
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
    getBooksCalled = true;
    lastSearch = search;
    lastGenre = genre;
    lastRating = rating;
    lastShelf = shelf;
    lastSort = sort;

    var filtered = mockBooksList;
    if (search != null && search.isNotEmpty) {
      filtered = filtered.where((b) => b.title.toLowerCase().contains(search.toLowerCase()) || b.author.toLowerCase().contains(search.toLowerCase())).toList();
    }
    if (genre != null && genre.isNotEmpty) {
      filtered = filtered.where((b) => b.genre == genre).toList();
    }
    if (shelf != null && shelf.isNotEmpty) {
      filtered = filtered.where((b) => b.shelf == shelf).toList();
    }
    if (rating != null) {
      filtered = filtered.where((b) => b.rating == rating).toList();
    }

    return {
      'books': filtered,
      'pagination': {
        'page': page,
        'limit': limit,
        'totalPages': 1,
        'totalBooks': filtered.length,
      }
    };
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
      child: const MaterialApp(
        home: BookListScreen(),
      ),
    );
  }

  void setupScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('BookListScreen Search & Filter Widget Tests', () {
    testWidgets('entering text in search updates book provider and calls API', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(mockBookRepository.getBooksCalled, isTrue);

      // Search by title "clean"
      await tester.enterText(find.byType(TextField), 'clean');
      await tester.pumpAndSettle();

      expect(mockBookRepository.lastSearch, 'clean');
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Design Patterns'), findsNothing);
    });

    testWidgets('applying shelf filter opens sheet and filters books', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      // Tap All Shelves filter chip
      await tester.tap(find.text('All Shelves'));
      await tester.pumpAndSettle();

      expect(find.text('Select Shelf'), findsOneWidget);

      // Select Finished Reading shelf
      await tester.tap(find.text('Finished Reading').last);
      await tester.pumpAndSettle();

      expect(mockBookRepository.lastShelf, 'Finished Reading');
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Design Patterns'), findsNothing);
    });

    testWidgets('applying genre filter opens sheet and filters books', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      // Tap All Genres filter chip
      await tester.tap(find.text('All Genres'));
      await tester.pumpAndSettle();

      expect(find.text('Select Genre'), findsOneWidget);

      // Select Technology genre
      await tester.tap(find.text('Technology').last);
      await tester.pumpAndSettle();

      expect(mockBookRepository.lastGenre, 'Technology');
      expect(find.text('Design Patterns'), findsOneWidget);
      expect(find.text('Clean Code'), findsNothing);
    });

    testWidgets('applying rating filter opens sheet and filters books', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      // Tap All Ratings filter chip
      await tester.tap(find.text('All Ratings'));
      await tester.pumpAndSettle();

      expect(find.text('Select Rating'), findsOneWidget);

      // Select 5 Stars
      await tester.tap(find.text('5 Stars').last);
      await tester.pumpAndSettle();

      expect(mockBookRepository.lastRating, 5);
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Design Patterns'), findsNothing);
    });

    testWidgets('displays appropriate empty state when no results match', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      // Search for something nonexistent
      await tester.enterText(find.byType(TextField), 'nonexistentbooktitle');
      await tester.pumpAndSettle();

      expect(find.text('No Matching Books'), findsOneWidget);
      expect(find.text('No results match your active filters or search terms.'), findsOneWidget);
    });
  });
}
