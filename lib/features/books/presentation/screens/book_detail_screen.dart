import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/api_config.dart';
import '../../domain/entities/book.dart';
import '../providers/book_provider.dart';
import '../widgets/book_cover_widget.dart';
import '../widgets/sakura_background.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  Book? _book;
  bool _isLoading = true;
  String? _error;
  int? _bookId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookId == null) {
      _bookId = ModalRoute.of(context)?.settings.arguments as int?;
      if (_bookId != null) {
        _loadBookDetails();
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Invalid Book ID';
        });
      }
    }
  }

  Future<void> _loadBookDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final book = await ref
        .read(bookNotifierProvider.notifier)
        .getBookDetails(_bookId!);

    if (mounted) {
      setState(() {
        _book = book;
        _isLoading = false;
        if (book == null) {
          _error =
              ref.read(bookNotifierProvider).errorMessage ??
              'Failed to load details.';
        }
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(color: Color(0xFF3A3142)),
        ),
        content: const Text(
          'Are you sure you want to remove this book from your collection?',
          style: TextStyle(color: Color(0xFF8B7E95)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8B7E95)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFF3A3142)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(bookNotifierProvider.notifier)
          .deleteBook(_book!.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book deleted successfully'),
            backgroundColor: Color(0xFFE78FB3),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  void _showChangeShelfBottomSheet(Book book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Move to Shelf',
                  style: TextStyle(
                    color: Color(0xFF3A3142),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Color(0xFFFFDCE8), height: 1),
              ...['Want To Read', 'Currently Reading', 'Finished Reading'].map((
                shelfOption,
              ) {
                final isCurrent = book.shelf == shelfOption;
                final color = _getShelfColor(shelfOption);
                return ListTile(
                  leading: Icon(
                    isCurrent ? Icons.bookmark : Icons.bookmark_outline,
                    color: color,
                  ),
                  title: Text(
                    shelfOption == 'Want To Read'
                        ? 'Wishlist'
                        : shelfOption == 'Currently Reading'
                        ? 'Reading'
                        : 'Completed',
                    style: TextStyle(
                      color: isCurrent
                          ? const Color(0xFF3A3142)
                          : const Color(0xFF8B7E95),
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: Color(0xFFE78FB3))
                      : null,
                  onTap: isCurrent
                      ? null
                      : () async {
                          Navigator.pop(context);
                          if (shelfOption == 'Finished Reading') {
                            _showAddReviewDialog(book);
                            return;
                          }
                          setState(() {
                            _isLoading = true;
                          });
                          final success = await ref
                              .read(bookNotifierProvider.notifier)
                              .updateBookShelf(book.id, shelfOption);
                          if (success) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Moved to "$shelfOption"'),
                                  backgroundColor: const Color(0xFFE78FB3),
                                ),
                              );
                              _loadBookDetails();
                            }
                          } else {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ref
                                            .read(bookNotifierProvider)
                                            .errorMessage ??
                                        'Failed to update shelf',
                                  ),
                                  backgroundColor: const Color(0xFFE57373),
                                ),
                              );
                            }
                          }
                        },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showUpdateProgressDialog(Book book) {
    final formKey = GlobalKey<FormState>();
    final currentPageController = TextEditingController(
      text: book.currentPage.toString(),
    );
    final totalPagesController = TextEditingController(
      text: book.totalPages.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        String? localError;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFFFF),
              title: const Text(
                'Update Reading Progress',
                style: TextStyle(
                  color: Color(0xFF3A3142),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (localError != null) ...[
                      Text(
                        localError!,
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: currentPageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF3A3142)),
                      decoration: InputDecoration(
                        labelText: 'Current Page',
                        labelStyle: const TextStyle(color: Color(0xFF8B7E95)),
                        filled: true,
                        fillColor: const Color(0xFFFFF8FA),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFFDCE8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE78FB3),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter current page';
                        }
                        final val = int.tryParse(value);
                        if (val == null) {
                          return 'Enter a valid number';
                        }
                        if (val < 0) {
                          return 'Page cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: totalPagesController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF3A3142)),
                      decoration: InputDecoration(
                        labelText: 'Total Pages',
                        labelStyle: const TextStyle(color: Color(0xFF8B7E95)),
                        filled: true,
                        fillColor: const Color(0xFFFFF8FA),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFFDCE8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE78FB3),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter total pages';
                        }
                        final val = int.tryParse(value);
                        if (val == null) {
                          return 'Enter a valid number';
                        }
                        if (val < 0) {
                          return 'Total pages cannot be negative';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF8B7E95)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE78FB3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final curr = int.parse(currentPageController.text);
                      final total = int.parse(totalPagesController.text);

                      if (curr > total) {
                        setStateDialog(() {
                          localError = 'Current page cannot exceed total pages';
                        });
                        return;
                      }

                      Navigator.pop(context);
                      setState(() {
                        _isLoading = true;
                      });

                      final success = await ref
                          .read(bookNotifierProvider.notifier)
                          .updateBookProgress(book.id, curr, total);

                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Reading progress updated successfully',
                              ),
                              backgroundColor: Color(0xFFE78FB3),
                            ),
                          );
                          _loadBookDetails();
                        }
                      } else {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ref.read(bookNotifierProvider).errorMessage ??
                                    'Failed to update progress',
                              ),
                              backgroundColor: const Color(0xFFE57373),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF3A3142)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddReviewDialog(Book book) {
    final formKey = GlobalKey<FormState>();
    int selectedRating = book.rating ?? 5;

    DateTime selectedDate = book.completionDate != null
        ? DateTime.tryParse(book.completionDate!) ?? DateTime.now()
        : DateTime.now();

    final dateController = TextEditingController(
      text:
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
    );
    final reviewController = TextEditingController(text: book.review ?? "");

    showDialog(
      context: context,
      builder: (context) {
        String? localError;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFFFF),
              title: Text(
                book.shelf == 'Finished Reading'
                    ? 'Edit Review & Rating'
                    : 'Mark as Completed',
                style: const TextStyle(
                  color: Color(0xFF3A3142),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (localError != null) ...[
                        Text(
                          localError!,
                          style: const TextStyle(
                            color: Color(0xFFE57373),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Star Rating Selector
                      const Text(
                        'Your Rating',
                        style: TextStyle(
                          color: Color(0xFF8B7E95),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starVal = index + 1;
                          final isSelected = starVal <= selectedRating;
                          return IconButton(
                            icon: Icon(
                              Icons.star,
                              color: isSelected
                                  ? const Color(0xFF5EEAD4)
                                  : const Color(0xFFFFDCE8),
                              size: 32,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                selectedRating = starVal;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Date Picker field
                      TextFormField(
                        controller: dateController,
                        readOnly: true,
                        style: const TextStyle(color: Color(0xFF3A3142)),
                        decoration: InputDecoration(
                          labelText: 'Completion Date',
                          labelStyle: const TextStyle(color: Color(0xFF8B7E95)),
                          filled: true,
                          fillColor: const Color(0xFFFFF8FA),
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF8B7E95),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFDCE8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE78FB3),
                            ),
                          ),
                        ),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFFE78FB3),
                                    onPrimary: Color(0xFFFFFFFF),
                                    surface: Color(0xFFFFFFFF),
                                    onSurface: Color(0xFF3A3142),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              selectedDate = pickedDate;
                              dateController.text =
                                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Review Field
                      TextFormField(
                        controller: reviewController,
                        maxLines: 4,
                        style: const TextStyle(color: Color(0xFF3A3142)),
                        decoration: InputDecoration(
                          labelText: 'Written Review (optional)',
                          labelStyle: const TextStyle(color: Color(0xFF8B7E95)),
                          hintText: 'Share your thoughts about this book...',
                          hintStyle: const TextStyle(color: Color(0xFF8B7E95)),
                          filled: true,
                          fillColor: const Color(0xFFFFF8FA),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFDCE8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE78FB3),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.length > 2000) {
                            return 'Review cannot exceed 2000 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF8B7E95)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE78FB3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (selectedDate.isAfter(DateTime.now())) {
                        setStateDialog(() {
                          localError =
                              'Completion date cannot be in the future';
                        });
                        return;
                      }

                      Navigator.pop(context);
                      setState(() {
                        _isLoading = true;
                      });

                      final success = await ref
                          .read(bookNotifierProvider.notifier)
                          .addReview(
                            book.id,
                            dateController.text,
                            selectedRating,
                            reviewController.text.trim(),
                          );

                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                book.shelf == 'Finished Reading'
                                    ? 'Review updated successfully'
                                    : 'Book marked as completed!',
                              ),
                              backgroundColor: const Color(0xFFE78FB3),
                            ),
                          );
                          _loadBookDetails();
                        }
                      } else {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ref.read(bookNotifierProvider).errorMessage ??
                                    'Failed to submit review',
                              ),
                              backgroundColor: const Color(0xFFE57373),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF3A3142)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getShelfColor(String shelf) {
    switch (shelf) {
      case 'Finished Reading':
        return const Color(0xFFE78FB3); // Rose Pink (Completed)
      case 'Currently Reading':
        return const Color(0xFF8B7E95); // Cozy Lavender (Reading)
      default:
        return const Color(0xFFF8BBD9); // Pastel Pink (Wishlist)
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE78FB3)),
        ),
      );
    }

    if (_error != null || _book == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8FA),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(
            _error ?? 'An error occurred',
            style: const TextStyle(color: Color(0xFFE57373), fontSize: 16),
          ),
        ),
      );
    }

    final book = _book!;
    final progressVal = book.totalPages > 0
        ? (book.currentPage / book.totalPages)
        : 0.0;
    final progressPercentage = (progressVal * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF3A3142)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF3A3142)),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/add-edit-book',
                arguments: book,
              );
              if (result == true) {
                _loadBookDetails();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE57373)),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SakuraBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book Cover Hero / Layout
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  height: 240,
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: book.coverImage != null
                      ? Image.network(
                          '${ApiConfig.baseUrl}${book.coverImage}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCoverPlaceholder(book),
                        )
                      : _buildCoverPlaceholder(book),
                ),
              ),

              // Metadata Detail
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A3142),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Author
                    Text(
                      'by ${book.author}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8B7E95),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meta Row (Genre, Year, Shelf)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(
                          label: book.genre,
                          icon: Icons.category_outlined,
                        ),
                        _buildChip(
                          label: 'Published: ${book.publicationYear}',
                          icon: Icons.calendar_today_outlined,
                        ),
                        GestureDetector(
                          onTap: () => _showChangeShelfBottomSheet(book),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getShelfColor(
                                book.shelf,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getShelfColor(
                                  book.shelf,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_outline,
                                  size: 16,
                                  color: _getShelfColor(book.shelf),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  book.shelf == 'Want To Read'
                                      ? 'Wishlist'
                                      : book.shelf == 'Currently Reading'
                                      ? 'Reading'
                                      : 'Completed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _getShelfColor(book.shelf),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Progress Section
                    if (book.shelf == 'Currently Reading') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reading Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3A3142),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFFE78FB3),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showUpdateProgressDialog(book),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progressVal,
                        backgroundColor: const Color(0xFFFFFFFF),
                        color: const Color(0xFFE78FB3),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page ${book.currentPage} of ${book.totalPages}',
                            style: const TextStyle(
                              color: Color(0xFF8B7E95),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$progressPercentage%',
                            style: const TextStyle(
                              color: Color(0xFFE78FB3),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Review & Rating Section
                    if (book.shelf == 'Finished Reading') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Rating & Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3A3142),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFFE78FB3),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showAddReviewDialog(book),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFDCE8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    Icons.star,
                                    color:
                                        book.rating != null && i < book.rating!
                                        ? const Color(0xFF5EEAD4)
                                        : const Color(0xFFFFDCE8),
                                    size: 20,
                                  ),
                                ),
                                if (book.completionDate != null) ...[
                                  const Spacer(),
                                  Text(
                                    'Completed: ${book.completionDate}',
                                    style: const TextStyle(
                                      color: Color(0xFF8B7E95),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              book.review.isNotEmpty
                                  ? book.review!
                                  : 'No written review provided.',
                              style: TextStyle(
                                color: book.review.isNotEmpty
                                    ? const Color(0xFF3A3142)
                                    : const Color(0xFF8B7E95),
                                fontStyle: book.review.isNotEmpty
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder(Book book) {
    return BookCoverWidget(
      title: book.title,
      author: book.author,
      fontSizeMultiplier: 1.25,
    );
  }

  Widget _buildChip({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFDCE8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8B7E95)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF3A3142), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

extension on String? {
  bool get isNotEmpty => this != null && this!.trim().isNotEmpty;
}
