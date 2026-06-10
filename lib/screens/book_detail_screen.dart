import 'package:flutter/material.dart';
import '../providers/book_provider.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class BookDetailScreen extends StatefulWidget {
  final BookProvider bookProvider;
  const BookDetailScreen({super.key, required this.bookProvider});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
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

    final book = await widget.bookProvider.getBookDetails(_bookId!);

    if (mounted) {
      setState(() {
        _book = book;
        _isLoading = false;
        if (book == null) {
          _error =
              widget.bookProvider.errorMessage ?? 'Failed to load details.';
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
          style: TextStyle(color: Color(0xFF4A2B33)),
        ),
        content: const Text(
          'Are you sure you want to remove this book from your collection?',
          style: TextStyle(color: Color(0xFF9A6A73)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9A6A73)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE85D75)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFF4A2B33)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.bookProvider.deleteBook(_book!.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book deleted successfully'),
            backgroundColor: Color(0xFFFF6F91),
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
                    color: Color(0xFF4A2B33),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Color(0xFFFFD6CC), height: 1),
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
                    shelfOption,
                    style: TextStyle(
                      color: isCurrent
                          ? Color(0xFF4A2B33)
                          : const Color(0xFF9A6A73),
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: Color(0xFFFF8FA3))
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
                          final success = await widget.bookProvider
                              .updateBookShelf(book.id, shelfOption);
                          if (success) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Moved to "$shelfOption"'),
                                  backgroundColor: const Color(0xFFFF6F91),
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
                                    widget.bookProvider.errorMessage ??
                                        'Failed to update shelf',
                                  ),
                                  backgroundColor: Color(0xFFE85D75),
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
                  color: Color(0xFF4A2B33),
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
                          color: Color(0xFFE85D75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: currentPageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF4A2B33)),
                      decoration: InputDecoration(
                        labelText: 'Current Page',
                        labelStyle: const TextStyle(color: Color(0xFF9A6A73)),
                        filled: true,
                        fillColor: const Color(0xFFFFF5F1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFFD6CC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF6F91),
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
                      style: const TextStyle(color: Color(0xFF4A2B33)),
                      decoration: InputDecoration(
                        labelText: 'Total Pages',
                        labelStyle: const TextStyle(color: Color(0xFF9A6A73)),
                        filled: true,
                        fillColor: const Color(0xFFFFF5F1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFFD6CC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF6F91),
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
                    style: TextStyle(color: Color(0xFF9A6A73)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F91),
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

                      final success = await widget.bookProvider
                          .updateBookProgress(book.id, curr, total);

                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Reading progress updated successfully',
                              ),
                              backgroundColor: Color(0xFFFF6F91),
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
                                widget.bookProvider.errorMessage ??
                                    'Failed to update progress',
                              ),
                              backgroundColor: Color(0xFFE85D75),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF4A2B33)),
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
    int selectedRating =
        book.rating ?? 5; // Default to 5 stars or existing rating
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
                  color: Color(0xFF4A2B33),
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
                            color: Color(0xFFE85D75),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Star Rating Selector
                      const Text(
                        'Your Rating',
                        style: TextStyle(
                          color: Color(0xFF9A6A73),
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
                                  ? Color(0xFFFF9EAA)
                                  : const Color(0xFFFFD6CC),
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
                        style: const TextStyle(color: Color(0xFF4A2B33)),
                        decoration: InputDecoration(
                          labelText: 'Completion Date',
                          labelStyle: const TextStyle(color: Color(0xFF9A6A73)),
                          filled: true,
                          fillColor: const Color(0xFFFFF5F1),
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF9A6A73),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFD6CC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6F91),
                            ),
                          ),
                        ),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(), // Restrict future dates
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFFFF6F91),
                                    onPrimary: Color(0xFF4A2B33),
                                    surface: Color(0xFFFFFFFF),
                                    onSurface: Color(0xFF4A2B33),
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
                        style: const TextStyle(color: Color(0xFF4A2B33)),
                        decoration: InputDecoration(
                          labelText: 'Written Review (optional)',
                          labelStyle: const TextStyle(color: Color(0xFF9A6A73)),
                          hintText: 'Share your thoughts about this book...',
                          hintStyle: const TextStyle(color: Color(0xFF9A6A73)),
                          filled: true,
                          fillColor: const Color(0xFFFFF5F1),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFD6CC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6F91),
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
                    style: TextStyle(color: Color(0xFF9A6A73)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F91),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // Validate completion date is not in future
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

                      final success = await widget.bookProvider.addReview(
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
                              backgroundColor: const Color(0xFFFF6F91),
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
                                widget.bookProvider.errorMessage ??
                                    'Failed to submit review',
                              ),
                              backgroundColor: Color(0xFFE85D75),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF4A2B33)),
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
        return Color(0xFFFF8FA3);
      case 'Currently Reading':
        return Color(0xFFFFB3C6);
      default:
        return Color(0xFFFFC09F);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF5F1),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6F91)),
        ),
      );
    }

    if (_error != null || _book == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF5F1),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(
            _error ?? 'An error occurred',
            style: const TextStyle(color: Color(0xFFE85D75), fontSize: 16),
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
      backgroundColor: const Color(0xFFFFF5F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4A2B33)),
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
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE85D75)),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: book.coverImage != null
                    ? Image.network(
                        '${BookService.baseUrl}${book.coverImage}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildCoverPlaceholder(),
                      )
                    : _buildCoverPlaceholder(),
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
                      color: Color(0xFF4A2B33),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Text(
                    'by ${book.author}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9A6A73),
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
                            color: _getShelfColor(book.shelf).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getShelfColor(
                                book.shelf,
                              ).withOpacity(0.3),
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
                                book.shelf,
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
                            color: Color(0xFF4A2B33),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFFFF6F91),
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
                      color: const Color(0xFFFF6F91),
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
                            color: Color(0xFF9A6A73),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$progressPercentage%',
                          style: const TextStyle(
                            color: Color(0xFFFF6F91),
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
                            color: Color(0xFF4A2B33),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFFFF6F91),
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
                        border: Border.all(color: const Color(0xFFFFD6CC)),
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
                                  color: book.rating != null && i < book.rating!
                                      ? Color(0xFFFF9EAA)
                                      : const Color(0xFFFFD6CC),
                                  size: 20,
                                ),
                              ),
                              if (book.completionDate != null) ...[
                                const Spacer(),
                                Text(
                                  'Completed: ${book.completionDate}',
                                  style: const TextStyle(
                                    color: Color(0xFF9A6A73),
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
                                  ? Color(0xFF4A2B33)
                                  : const Color(0xFF9A6A73),
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
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: const Color(0xFFFFD6CC),
      child: const Center(
        child: Icon(Icons.book, size: 64, color: Color(0xFF9A6A73)),
      ),
    );
  }

  Widget _buildChip({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD6CC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9A6A73)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF4A2B33), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

extension on String? {
  bool get isNotEmpty => this != null && this!.trim().isNotEmpty;
}
