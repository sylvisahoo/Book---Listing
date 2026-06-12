import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/config/api_config.dart';
import '../../domain/entities/book.dart';
import '../providers/book_provider.dart';
import '../widgets/book_cover_widget.dart';
import '../widgets/sakura_background.dart';

class AddEditBookScreen extends ConsumerStatefulWidget {
  const AddEditBookScreen({super.key});

  @override
  ConsumerState<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends ConsumerState<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();

  Book? _existingBook;
  bool _isEditMode = false;
  bool _initialized = false;

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _genreController = TextEditingController();
  final _yearController = TextEditingController();
  final _currentPageController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _completionDateController = TextEditingController();
  final _reviewController = TextEditingController();

  String _selectedShelf = 'Want To Read';
  int _selectedRating = 5;
  String? _selectedImagePath;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _authorController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _existingBook = ModalRoute.of(context)?.settings.arguments as Book?;
      if (_existingBook != null) {
        _isEditMode = true;
        _titleController.text = _existingBook!.title;
        _authorController.text = _existingBook!.author;
        _genreController.text = _existingBook!.genre;
        _yearController.text = _existingBook!.publicationYear.toString();
        _currentPageController.text = _existingBook!.currentPage.toString();
        _totalPagesController.text = _existingBook!.totalPages.toString();
        _selectedShelf = _existingBook!.shelf;
        _reviewController.text = _existingBook!.review ?? '';
        _completionDateController.text = _existingBook!.completionDate ?? '';
        _selectedRating = _existingBook!.rating ?? 5;
      } else {
        _yearController.text = DateTime.now().year.toString();
        _currentPageController.text = '0';
        _totalPagesController.text = '0';
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _authorController.removeListener(_onTextChanged);
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _currentPageController.dispose();
    _totalPagesController.dispose();
    _completionDateController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick cover image')),
      );
    }
  }

  Future<void> _selectCompletionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    if (picked != null) {
      setState(() {
        _completionDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final fields = {
      'title': _titleController.text.trim(),
      'author': _authorController.text.trim(),
      'genre': _genreController.text.trim(),
      'publication_year': _yearController.text.trim(),
      'shelf': _selectedShelf,
      'current_page': _selectedShelf == 'Currently Reading'
          ? _currentPageController.text.trim()
          : '0',
      'total_pages': _selectedShelf == 'Currently Reading'
          ? _totalPagesController.text.trim()
          : '0',
      if (_selectedShelf == 'Finished Reading') ...{
        'completion_date': _completionDateController.text.trim(),
        'rating': _selectedRating.toString(),
        if (_reviewController.text.isNotEmpty)
          'review': _reviewController.text.trim(),
      },
    };

    bool success;
    if (_isEditMode) {
      success = await ref
          .read(bookNotifierProvider.notifier)
          .editBook(_existingBook!.id, fields, _selectedImagePath);
    } else {
      success = await ref
          .read(bookNotifierProvider.notifier)
          .addBook(fields, _selectedImagePath);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Book updated successfully'
                : 'Book added successfully',
          ),
          backgroundColor: const Color(0xFFE78FB3),
        ),
      );
      Navigator.pop(context, true);
    } else {
      final bookState = ref.read(bookNotifierProvider);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          title: const Text(
            'Error',
            style: TextStyle(color: Color(0xFF3A3142)),
          ),
          content: Text(
            bookState.errorMessage ?? 'Operation failed.',
            style: const TextStyle(color: Color(0xFF8B7E95)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFE78FB3)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookNotifierProvider);
    final isLoading = bookState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF3A3142)),
        title: Text(
          _isEditMode ? 'Edit Book' : 'Add Book',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF3A3142),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF3A3142)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SakuraBackground(
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE78FB3)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cover Picker Box
                        GestureDetector(
                          onTap: _pickImage,
                          child: Center(
                            child: Container(
                              height: 200,
                              width: 140,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFFDCE8),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _selectedImagePath != null
                                  ? Image.file(
                                      File(_selectedImagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : _isEditMode &&
                                        _existingBook!.coverImage != null
                                  ? Image.network(
                                      '${ApiConfig.baseUrl}${_existingBook!.coverImage}',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildCoverPlaceholder(),
                                    )
                                  : _buildCoverPlaceholder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFFFDCE8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              TextFormField(
                                controller: _titleController,
                                style: const TextStyle(
                                  color: Color(0xFF3A3142),
                                ),
                                decoration: _buildInputDecoration(
                                  'Book Title',
                                  Icons.title,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Title is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Author
                              TextFormField(
                                controller: _authorController,
                                style: const TextStyle(
                                  color: Color(0xFF3A3142),
                                ),
                                decoration: _buildInputDecoration(
                                  'Author',
                                  Icons.person_outline,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Author is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Genre
                              TextFormField(
                                controller: _genreController,
                                style: const TextStyle(
                                  color: Color(0xFF3A3142),
                                ),
                                decoration: _buildInputDecoration(
                                  'Genre',
                                  Icons.category_outlined,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Genre is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Publication Year
                              TextFormField(
                                controller: _yearController,
                                style: const TextStyle(
                                  color: Color(0xFF3A3142),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration(
                                  'Publication Year',
                                  Icons.calendar_today_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Publication year is required';
                                  }
                                  final year = int.tryParse(value.trim());
                                  final currentYear = DateTime.now().year;
                                  if (year == null ||
                                      year < 1000 ||
                                      year > currentYear) {
                                    return 'Invalid year (1000 - $currentYear)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Shelf Assignment Selector
                              DropdownButtonFormField<String>(
                                value: _selectedShelf,
                                style: const TextStyle(
                                  color: Color(0xFF3A3142),
                                ),
                                dropdownColor: const Color(0xFFFFFFFF),
                                decoration: _buildInputDecoration(
                                  'Shelf',
                                  Icons.bookmark_outline,
                                ),
                                items:
                                    [
                                          'Want To Read',
                                          'Currently Reading',
                                          'Finished Reading',
                                        ]
                                        .map(
                                          (shelf) => DropdownMenuItem(
                                            value: shelf,
                                            child: Text(shelf),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedShelf = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 24),

                              // Currently Reading Progress Fields
                              if (_selectedShelf == 'Currently Reading') ...[
                                const Text(
                                  'Reading Progress',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3A3142),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _currentPageController,
                                        style: const TextStyle(
                                          color: Color(0xFF3A3142),
                                        ),
                                        keyboardType: TextInputType.number,
                                        decoration: _buildInputDecoration(
                                          'Current Page',
                                          Icons.find_in_page_outlined,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          final val = int.tryParse(
                                            value.trim(),
                                          );
                                          if (val == null || val < 0) {
                                            return 'Invalid';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _totalPagesController,
                                        style: const TextStyle(
                                          color: Color(0xFF3A3142),
                                        ),
                                        keyboardType: TextInputType.number,
                                        decoration: _buildInputDecoration(
                                          'Total Pages',
                                          Icons.library_books_outlined,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          final val = int.tryParse(
                                            value.trim(),
                                          );
                                          if (val == null || val < 0) {
                                            return 'Invalid';
                                          }
                                          final currVal = int.tryParse(
                                            _currentPageController.text,
                                          );
                                          if (currVal != null &&
                                              val < currVal) {
                                            return 'Must be >= Current';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Finished Reading Reviews/Ratings Fields
                              if (_selectedShelf == 'Finished Reading') ...[
                                const Text(
                                  'Review Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3A3142),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Completion Date
                                TextFormField(
                                  controller: _completionDateController,
                                  style: const TextStyle(
                                    color: Color(0xFF3A3142),
                                  ),
                                  readOnly: true,
                                  onTap: _selectCompletionDate,
                                  decoration: _buildInputDecoration(
                                    'Completion Date',
                                    Icons.date_range_outlined,
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Completion date is required'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Star Rating Selector
                                DropdownButtonFormField<int>(
                                  value: _selectedRating,
                                  style: const TextStyle(
                                    color: Color(0xFF3A3142),
                                  ),
                                  dropdownColor: const Color(0xFFFFFFFF),
                                  decoration: _buildInputDecoration(
                                    'Rating',
                                    Icons.star_border,
                                  ),
                                  items: [5, 4, 3, 2, 1]
                                      .map(
                                        (stars) => DropdownMenuItem(
                                          value: stars,
                                          child: Text('$stars Stars'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedRating = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Review Text
                                TextFormField(
                                  controller: _reviewController,
                                  style: const TextStyle(
                                    color: Color(0xFF3A3142),
                                  ),
                                  maxLines: 4,
                                  decoration: _buildInputDecoration(
                                    'Write a Review (Optional)',
                                    Icons.rate_review_outlined,
                                  ),
                                  validator: (value) {
                                    if (value != null && value.length > 2000) {
                                      return 'Review cannot exceed 2000 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE78FB3), Color(0xFFF8BBD9)],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              _isEditMode ? 'Update Book' : 'Save Book',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    if (title.isEmpty && author.isEmpty) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Color(0xFF8B7E95),
          ),
          SizedBox(height: 8),
          Text(
            'Upload Cover',
            style: TextStyle(color: Color(0xFF8B7E95), fontSize: 12),
          ),
        ],
      );
    }
    return BookCoverWidget(
      title: title.isNotEmpty ? title : 'Book Title',
      author: author.isNotEmpty ? author : 'Author Name',
      fontSizeMultiplier: 1.15,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8B7E95)),
      prefixIcon: Icon(icon, color: const Color(0xFF8B7E95)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFFDCE8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE78FB3), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
      ),
    );
  }
}
