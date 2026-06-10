import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkAuthStatus();
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clear errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check stored credentials on start
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _currentUser = await _authService.getUser();
        _isAuthenticated = _currentUser != null;
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  // Perform login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      final data = await _authService.login(email, password);
      _currentUser = data['user'];
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _currentUser = null;
      _setLoading(false);
      return false;
    }
  }

  // Perform registration
  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    _setLoading(true);
    clearError();
    try {
      final data = await _authService.register(name, email, password, confirmPassword);
      _currentUser = data['user'];
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _currentUser = null;
      _setLoading(false);
      return false;
    }
  }

  // Perform logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
    } catch (_) {
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _setLoading(false);
    }
  }

  // Request password reset token
  Future<String?> requestPasswordReset(String email) async {
    _setLoading(true);
    clearError();
    try {
      final token = await _authService.requestPasswordReset(email);
      _setLoading(false);
      return token;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  // Execute password reset
  Future<bool> resetPassword(
    String token,
    String newPassword,
    String confirmPassword,
  ) async {
    _setLoading(true);
    clearError();
    try {
      await _authService.resetPassword(token, newPassword, confirmPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }
}
