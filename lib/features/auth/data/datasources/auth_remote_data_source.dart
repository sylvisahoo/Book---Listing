import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../domain/entities/user_entity.dart';

class AuthRemoteDataSource {
  String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      return {
        'token': data['token'] as String,
        'user': UserEntity.fromJson(data['user'] as Map<String, dynamic>),
      };
    } else {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return {
        'token': data['token'] as String,
        'user': UserEntity.fromJson(data['user'] as Map<String, dynamic>),
      };
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  Future<void> logout(String token) async {
    final url = Uri.parse('$baseUrl/api/auth/logout');
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<String> requestPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/api/auth/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data['token'] ?? '';
    } else {
      throw Exception(data['error'] ?? 'Reset request failed');
    }
  }

  Future<void> resetPassword(
    String token,
    String newPassword,
    String confirmPassword,
  ) async {
    final url = Uri.parse('$baseUrl/api/auth/reset-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Password reset failed');
    }
  }
}
