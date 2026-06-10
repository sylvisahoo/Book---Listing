class Book {
  final int id;
  final int userId;
  final String title;
  final String author;
  final String genre;
  final int publicationYear;
  final String? coverImage;
  final String shelf;
  final int currentPage;
  final int totalPages;
  final String? completionDate;
  final int? rating;
  final String? review;
  final String? createdAt;

  Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.publicationYear,
    this.coverImage,
    required this.shelf,
    required this.currentPage,
    required this.totalPages,
    this.completionDate,
    this.rating,
    this.review,
    this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      author: json['author'] as String,
      genre: json['genre'] as String,
      publicationYear: json['publication_year'] as int,
      coverImage: json['cover_image'] as String?,
      shelf: json['shelf'] as String? ?? 'Want To Read',
      currentPage: json['current_page'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
      completionDate: json['completion_date'] as String?,
      rating: json['rating'] as int?,
      review: json['review'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'author': author,
      'genre': genre,
      'publication_year': publicationYear,
      'cover_image': coverImage,
      'shelf': shelf,
      'current_page': currentPage,
      'total_pages': totalPages,
      'completion_date': completionDate,
      'rating': rating,
      'review': review,
      'created_at': createdAt,
    };
  }
}
