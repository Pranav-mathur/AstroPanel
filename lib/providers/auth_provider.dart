import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _token;
  String? _userId;
  bool? _isNewUser;
  String? _error;

  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get userId => _userId;
  bool? get isNewUser => _isNewUser;
  String? get error => _error;
  bool get isAuthenticated {
    // If token doesn't exist, user is not authenticated
    if (_token == null || _token!.isEmpty) {
      return false;
    }

    // If token exists but isNewUser is null, consider authenticated
    // (backward compatibility for existing users)
    if (_isNewUser == null) {
      return true;
    }

    // If token exists and user is NOT new, they are authenticated
    // If user is new, they need to complete onboarding first
    return !_isNewUser!;
  }

  // Load token and user data from storage on app start
  Future<void> loadToken() async {
    _token = await _storage.read(key: 'token');
    _userId = await _storage.read(key: 'userId');

    // Load is_new_user
    final isNewUserString = await _storage.read(key: 'is_new_user');
    if (isNewUserString != null) {
      _isNewUser = isNewUserString.toLowerCase() == 'true';
    }

    notifyListeners();
  }

  // Send OTP to mobile number (same as login)
  Future<bool> login(String mobileNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.sendOtp(mobileNumber);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp(String mobileNumber) async {
    return await login(mobileNumber);
  }

  // Verify OTP and save token
  Future<Map<String, dynamic>?> verifyOtp(String mobileNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOtp(mobileNumber, otp);

      _token = result["token"];
      _userId = result["userId"];

      // Extract is_new_user from response
      if (result.containsKey("is_new_user")) {
        _isNewUser = result["is_new_user"] == true || result["is_new_user"] == "true";
      } else if (result.containsKey("isNewUser")) {
        _isNewUser = result["isNewUser"] == true || result["isNewUser"] == "true";
      }

      if (_token == null) {
        throw Exception("Token not found in response");
      }

      // Persist token, userId, and isNewUser securely
      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'userId', value: _userId);

      if (_isNewUser != null) {
        await _storage.write(key: 'is_new_user', value: _isNewUser.toString());
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }

  // Create Astrologer Profile
  Future<Map<String, dynamic>?> createAstrologerProfile(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get token from storage if not in memory
      final token = _token ?? await _storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final result = await _authService.createAstrologerProfile(
        token: token,
        payload: payload,
      );

      // After successful profile creation, mark user as no longer new
      _isNewUser = false;
      await _storage.write(key: 'is_new_user', value: 'false');

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update is_new_user status (useful after completing onboarding)
  Future<void> updateIsNewUser(bool isNewUser) async {
    _isNewUser = isNewUser;
    await _storage.write(key: 'is_new_user', value: isNewUser.toString());
    notifyListeners();
  }

  // Mark user as no longer new (completed onboarding)
  Future<void> completeOnboarding() async {
    await updateIsNewUser(false);
  }

  // Logout
  Future<void> logout() async {
    if (_token != null) {
      try {
        await _authService.logout(_token!);
      } catch (e) {
        debugPrint("Logout API error: $e");
      }
    }

    _token = null;
    _userId = null;
    _isNewUser = null;
    _error = null;
    notifyListeners();

    // Remove all auth data from storage
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'is_new_user');
    // await _storage.delete(key: 'is_new_user');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}