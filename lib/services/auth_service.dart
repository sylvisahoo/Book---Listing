import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;

  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Helper to save token and user info
  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(user));
  }

  // Retrieve stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Retrieve stored user info
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return json.decode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  // Clear stored session details
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Register a new user
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
      final token = data['token'];
      final user = data['user'];
      await _saveSession(token, user);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  // Log in user
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      final token = data['token'];
      final user = data['user'];
      await _saveSession(token, user);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  // Log out user
  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      final url = Uri.parse('$baseUrl/api/auth/logout');
      try {
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {
        // Continue clearing session locally even if API fails
      }
    }
    await clearSession();
  }

  // Request password reset token
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

  // Complete password reset
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
