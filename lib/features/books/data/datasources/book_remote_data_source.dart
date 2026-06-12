import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/book.dart';

class BookRemoteDataSource {
  final AuthLocalDataSource authLocalDataSource;

  BookRemoteDataSource({required this.authLocalDataSource});

  String get baseUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() => authLocalDataSource.getToken();

  Future<Map<String, dynamic>> getBooks({
    String? search,
    String? genre,
    int? rating,
    String? shelf,
    String? sort,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _getToken();
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (genre != null && genre.isNotEmpty) 'genre': genre,
      if (rating != null) 'rating': rating.toString(),
      if (shelf != null && shelf.isNotEmpty) 'shelf': shelf,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final uri = Uri.parse('$baseUrl/api/books').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      final List<dynamic> booksJson = data['books'] ?? [];
      final books = booksJson.map((json) => Book.fromJson(json)).toList();
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      return {'books': books, 'pagination': pagination};
    } else {
      throw Exception(data['error'] ?? 'Failed to load books');
    }
  }

  Future<Book> getBook(int id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/books/$id');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return Book.fromJson(data['book']);
    } else {
      throw Exception(data['error'] ?? 'Failed to load book details');
    }
  }

  Future<Book> addBook(Map<String, String> fields, String? coverPath) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/books');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);

    if (coverPath != null && coverPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('cover', coverPath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = json.decode(response.body);

    if (response.statusCode == 201) {
      return Book.fromJson(data['book']);
    } else {
      throw Exception(data['error'] ?? 'Failed to add book');
    }
  }

  Future<Book> editBook(
    int id,
    Map<String, String> fields,
    String? coverPath,
  ) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/books/$id');
    final request = http.MultipartRequest('PUT', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);

    if (coverPath != null && coverPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('cover', coverPath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      return Book.fromJson(data['book']);
    } else {
      throw Exception(data['error'] ?? 'Failed to edit book');
    }
  }

  Future<void> deleteBook(int id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/books/$id');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete book');
    }
  }

  Future<Book> updateBookShelf(int id, String shelf) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/books/$id/shelf');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'shelf': shelf}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return Book.fromJson(data['book']);
    } else {
      throw Exception(data['error'] ?? 'Failed to update shelf');
    }
  }

  Future<Book> updateBookProgress(
    int id,
    int currentPage,
    int totalPages,
  ) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/books/$id/progress');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'current_page': currentPage,
        'total_pages': totalPages,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return Book.fromJson(data['book']);
    } else {
      throw Exception(data['error'] ?? 'Failed to update reading progress');
    }
  }

  Future<Map<String, int>> getShelfStats() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/books/shelves/stats');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return {
        'wantToRead': data['wantToRead'] as int? ?? 0,
        'currentlyReading': data['currentlyReading'] as int? ?? 0,
        'finishedReading': data['finishedReading'] as int? ?? 0,
      };
    } else {
      throw Exception(data['error'] ?? 'Failed to load shelf stats');
    }
  }

  Future<Book> addReview(
    int id,
    String completionDate,
    int rating,
    String? review,
  ) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/books/$id/review');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'completion_date': completionDate,
        'rating': rating,
        'review': review ?? '',
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return Book.fromJson(data['book']);
    } else {
      throw Exception(data['error'] ?? 'Failed to submit review');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/dashboard/stats');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to load dashboard stats');
    }
  }

  Future<List<dynamic>> getGoals() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/goals');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data['goals'] as List<dynamic>? ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load reading goals');
    }
  }

  Future<Map<String, dynamic>> createGoal(int targetBooks, int year) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/goals');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'target_books': targetBooks, 'year': year}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      return data['goal'] as Map<String, dynamic>? ?? {};
    } else {
      throw Exception(data['error'] ?? 'Failed to create goal');
    }
  }

  Future<Map<String, dynamic>> updateGoal(int id, int targetBooks) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/goals/$id');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'target_books': targetBooks}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data['goal'] as Map<String, dynamic>? ?? {};
    } else {
      throw Exception(data['error'] ?? 'Failed to update goal');
    }
  }
}
