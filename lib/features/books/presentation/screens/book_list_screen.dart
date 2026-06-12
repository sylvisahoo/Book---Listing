import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/api_config.dart';
import '../../domain/entities/book.dart';
import '../providers/book_provider.dart';

class BookListScreen extends ConsumerStatefulWidget {
  const BookListScreen({super.key});

  @override
  ConsumerState<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends ConsumerState<BookListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(bookNotifierProvider).searchText;
      ref.read(bookNotifierProvider.notifier).fetchBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to get shelf tag color
  Color _getShelfColor(String shelf) {
    switch (shelf) {
      case 'Finished Reading':
        return const Color(0xFFFF8FA3);
      case 'Currently Reading':
        return const Color(0xFFFFB3C6);
      default:
        return const Color(0xFFFFC09F);
    }
  }

  // Dropdown filter widgets
  Widget _buildFilterRow(BookState state, BookNotifier notifier) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Shelf Filter
          _buildFilterChip<String>(
            label: state.selectedShelf ?? 'All Shelves',
            isActive: state.selectedShelf != null,
            onPressed: () => _showShelfSelector(state, notifier),
          ),
          const SizedBox(width: 8),

          // Genre Filter
          _buildFilterChip<String>(
            label: state.selectedGenre ?? 'All Genres',
            isActive: state.selectedGenre != null,
            onPressed: () => _showGenreSelector(state, notifier),
          ),
          const SizedBox(width: 8),

          // Rating Filter
          _buildFilterChip<int>(
            label: state.selectedRating != null
                ? '${state.selectedRating} Stars'
                : 'All Ratings',
            isActive: state.selectedRating != null,
            onPressed: () => _showRatingSelector(state, notifier),
          ),
          const SizedBox(width: 8),

          // Sort Filter
          _buildFilterChip<String>(
            label: 'Sort: ${state.sortOption}',
            isActive: true,
            onPressed: () => _showSortSelector(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip<T>({
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ActionChip(
      onPressed: onPressed,
      label: Text(label),
      labelStyle: TextStyle(
        color: isActive ? const Color(0xFF4A2B33) : const Color(0xFF9A6A73),
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: isActive
          ? const Color(0xFFFF6F91)
          : const Color(0xFFFFFFFF),
      side: BorderSide(
        color: isActive ? const Color(0xFFFF6F91) : const Color(0xFFFFD6CC),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // Filter selection dialogs
  void _showShelfSelector(BookState state, BookNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text(
              'Select Shelf',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('All Shelves'),
            onTap: () {
              notifier.setShelf(null);
              Navigator.pop(context);
            },
          ),
          ...['Want To Read', 'Currently Reading', 'Finished Reading'].map(
            (shelf) => ListTile(
              title: Text(shelf),
              onTap: () {
                notifier.setShelf(shelf);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showGenreSelector(BookState state, BookNotifier notifier) {
    final genres = [
      'Fiction',
      'Non-Fiction',
      'Science Fiction',
      'Self-Help',
      'Technology',
      'Psychology',
      'Fantasy',
      'Science',
      'Business',
      'Philosophy',
      'Dystopian',
      'Memoir',
      'Finance',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text(
              'Select Genre',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('All Genres'),
            onTap: () {
              notifier.setGenre(null);
              Navigator.pop(context);
            },
          ),
          ...genres.map(
            (genre) => ListTile(
              title: Text(genre),
              onTap: () {
                notifier.setGenre(genre);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingSelector(BookState state, BookNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text(
              'Select Rating',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('All Ratings'),
            onTap: () {
              notifier.setRating(null);
              Navigator.pop(context);
            },
          ),
          ...[5, 4, 3, 2, 1].map(
            (rating) => ListTile(
              title: Text('$rating Stars'),
              onTap: () {
                notifier.setRating(rating);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSelector(BookState state, BookNotifier notifier) {
    final sortOptions = {
      'newest': 'Newest Additions',
      'oldest': 'Oldest Additions',
      'title_asc': 'Title (A-Z)',
      'title_desc': 'Title (Z-A)',
      'author_asc': 'Author Name',
      'highest_rated': 'Highest Rated',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text(
              'Sort By',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...sortOptions.entries.map(
            (entry) => ListTile(
              title: Text(entry.value),
              onTap: () {
                notifier.setSort(entry.key);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookNotifierProvider);
    final notifier = ref.read(bookNotifierProvider.notifier);
    final books = bookState.books;
    final isLoading = bookState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F1),
      appBar: AppBar(
        title: const Text(
          'My Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (bookState.selectedGenre != null ||
              bookState.selectedRating != null ||
              bookState.selectedShelf != null ||
              bookState.searchText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Color(0xFFFF6F91)),
              onPressed: () {
                _searchController.clear();
                notifier.clearFilters();
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (val) => notifier.setSearchText(val),
              style: const TextStyle(color: Color(0xFF4A2B33)),
              decoration: InputDecoration(
                hintText: 'Search by title or author...',
                hintStyle: const TextStyle(color: Color(0xFF9A6A73)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9A6A73)),
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFFD6CC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF6F91),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Shelf Stats Summary Header
            _buildStatsHeader(bookState),

            // Filter tags row
            _buildFilterRow(bookState, notifier),
            const SizedBox(height: 16),

            // Book Grid / Lists
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6F91),
                      ),
                    )
                  : books.isEmpty
                      ? _buildEmptyState(bookState, notifier)
                      : Column(
                          children: [
                            Expanded(
                              child: GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.65,
                                ),
                                itemCount: books.length,
                                itemBuilder: (context, index) {
                                  final book = books[index];
                                  return _buildBookCard(book);
                                },
                              ),
                            ),
                            // Pagination Footer
                            _buildPaginationControls(bookState, notifier),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6F91),
        child: const Icon(Icons.add, color: Color(0xFF4A2B33)),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-edit-book');
          if (result == true) {
            notifier.fetchBooks();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(BookState state, BookNotifier notifier) {
    final hasActiveFilters = state.selectedGenre != null ||
        state.selectedRating != null ||
        state.selectedShelf != null ||
        state.searchText.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 80, color: Color(0xFFFFD6CC)),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters ? 'No Matching Books' : 'No Books Found',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF4A2B33),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              hasActiveFilters
                  ? 'No results match your active filters or search terms.'
                  : 'Add your first book or adjust filters.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9A6A73)),
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F91),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.filter_alt_off, color: Color(0xFF4A2B33), size: 18),
              label: const Text(
                'Clear All Filters',
                style: TextStyle(
                  color: Color(0xFF4A2B33),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                _searchController.clear();
                notifier.clearFilters();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/book-detail', arguments: book.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD6CC)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            Expanded(
              child: book.coverImage != null
                  ? Image.network(
                      '${ApiConfig.baseUrl}${book.coverImage}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildCoverPlaceholder(),
                    )
                  : _buildCoverPlaceholder(),
            ),

            // Metadata
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF4A2B33),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A6A73),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Shelf & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getShelfColor(book.shelf).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book.shelf == 'Want To Read'
                              ? 'Want'
                              : book.shelf == 'Currently Reading'
                                  ? 'Reading'
                                  : 'Read',
                          style: TextStyle(
                            fontSize: 10,
                            color: _getShelfColor(book.shelf),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (book.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Color(0xFFFF9EAA),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${book.rating}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFF9EAA),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: const Color(0xFFFFD6CC),
      child: const Center(
        child: Icon(Icons.book, size: 48, color: Color(0xFF9A6A73)),
      ),
    );
  }

  Widget _buildPaginationControls(BookState state, BookNotifier notifier) {
    if (state.totalPages <= 1) return const SizedBox(height: 16);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            color: state.currentPage > 1
                ? const Color(0xFFFF6F91)
                : const Color(0xFFFFD6CC),
            onPressed: state.currentPage > 1
                ? () => notifier.setPage(state.currentPage - 1)
                : null,
          ),
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: const TextStyle(color: Color(0xFF4A2B33), fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            color: state.currentPage < state.totalPages
                ? const Color(0xFFFF6F91)
                : const Color(0xFFFFD6CC),
            onPressed: state.currentPage < state.totalPages
                ? () => notifier.setPage(state.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(BookState state) {
    final stats = state.shelfStats;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD6CC)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Want to Read',
            stats['wantToRead'] ?? 0,
            const Color(0xFFFFC09F),
          ),
          _buildDivider(),
          _buildStatItem(
            'Reading',
            stats['currentlyReading'] ?? 0,
            const Color(0xFFFFB3C6),
          ),
          _buildDivider(),
          _buildStatItem(
            'Finished',
            stats['finishedReading'] ?? 0,
            const Color(0xFFFF8FA3),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 24, width: 1, color: const Color(0xFFFFD6CC));
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9A6A73)),
        ),
      ],
    );
  }
}
