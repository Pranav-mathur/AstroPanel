import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = "http://98.91.1.108:8000";
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'token';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userIdKey = 'userId';
  static const String _isNewUserKey = 'is_new_user';

  // Get token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // Save token
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  // Get phone number
  Future<String?> getPhoneNumber() async {
    try {
      return await _secureStorage.read(key: _phoneNumberKey);
    } catch (e) {
      debugPrint('Error getting phone number: $e');
      return null;
    }
  }

  // Save phone number
  Future<void> savePhoneNumber(String phoneNumber) async {
    try {
      await _secureStorage.write(key: _phoneNumberKey, value: phoneNumber);
    } catch (e) {
      debugPrint('Error saving phone number: $e');
    }
  }

  // Get user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  // Save user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _secureStorage.write(key: _userIdKey, value: userId);
    } catch (e) {
      debugPrint('Error saving user ID: $e');
    }
  }

  // Get is_new_user status
  Future<bool?> getIsNewUser() async {
    try {
      final value = await _secureStorage.read(key: _isNewUserKey);
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error getting is_new_user: $e');
      return null;
    }
  }

  // Save is_new_user status
  Future<void> saveIsNewUser(bool isNewUser) async {
    try {
      await _secureStorage.write(key: _isNewUserKey, value: isNewUser.toString());
    } catch (e) {
      debugPrint('Error saving is_new_user: $e');
    }
  }

  // Send OTP to mobile number
  Future<Map<String, dynamic>> sendOtp(String mobileNumber) async {
    final url = Uri.parse("$baseUrl/api/auth/send-otp");
    debugPrint("✅ Send OTP API Payload: $mobileNumber");

    // Save phone number for later use
    await savePhoneNumber(mobileNumber);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phoneNumber": mobileNumber, "role": "astrologer"}),
    );

    debugPrint("✅ Send OTP API URL: ${url}");
    debugPrint("✅ Send OTP API Response: ${response.statusCode}");
    debugPrint("✅ Send OTP API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return {
        "message": "OTP sent successfully"
      };
    } else {
      // Handle specific error cases
      if (response.statusCode == 400) {
        throw Exception("Invalid mobile number format");
      } else if (response.statusCode == 500) {
        throw Exception("Failed to send OTP. Please try again.");
      } else {
        throw Exception("Failed to send OTP: ${response.body}");
      }
    }
  }

  // Verify OTP and get JWT token
  Future<Map<String, dynamic>> verifyOtp(String mobileNumber, String otp) async {
    final url = Uri.parse("$baseUrl/api/auth/verify-otp");
    debugPrint("✅ Verify OTP API Payload: mobileNumber=$mobileNumber, otp=$otp");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phoneNumber": mobileNumber.trim(),
        "otp": otp.trim(),
        "role": "astrologer"
      }),
    );

    var gg = jsonEncode({
      "phoneNumber": mobileNumber,
      "otp": otp,
      "role": "astrologer"
    });

    debugPrint("✅ Verify OTP API Response: ${gg}");
    debugPrint("✅ Verify OTP API Response: ${url}");
    debugPrint("✅ Verify OTP API Response: ${response.statusCode}");
    debugPrint("✅ Verify OTP API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      // Save token, userId, phoneNumber, and is_new_user to secure storage
      if (result['token'] != null) {
        await saveToken(result['token']);
        await savePhoneNumber(mobileNumber);

        if (result['userId'] != null) {
          await saveUserId(result['userId']);
        }

        // Save is_new_user status if present in response
        if (result.containsKey('is_new_user')) {
          final isNewUser = result['is_new_user'] == true || result['is_new_user'] == 'true';
          await saveIsNewUser(isNewUser);
        } else if (result.containsKey('isNewUser')) {
          final isNewUser = result['isNewUser'] == true || result['isNewUser'] == 'true';
          await saveIsNewUser(isNewUser);
        }
      }

      return result;
    } else {
      // Handle specific error cases
      if (response.statusCode == 400) {
        throw Exception("Mobile number and OTP are required");
      } else if (response.statusCode == 401) {
        throw Exception("Invalid OTP. Please try again.");
      } else if (response.statusCode == 500) {
        throw Exception("Server error. Please try again.");
      } else {
        throw Exception("OTP verification failed: ${response.body}");
      }
    }
  }

  // Logout method
  Future<Map<String, dynamic>> logout(String token) async {
    final url = Uri.parse("$baseUrl/auth/logout");
    debugPrint("✅ Logout API called");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("✅ Logout API Response: ${response.statusCode}");
    debugPrint("✅ Logout API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      // Clear all secure storage
      await clearAll();
      return jsonDecode(response.body);
    } else {
      throw Exception("Logout failed: ${response.body}");
    }
  }

  // Updated login method - now sends OTP instead of direct login
  Future<Map<String, dynamic>> loginWithPhone(String mobileNumber) async {
    return await sendOtp(mobileNumber);
  }

  // Method to make authenticated requests
  Future<http.Response> makeAuthenticatedRequest(
      String endpoint,
      String token, {
        String method = 'GET',
        Map<String, dynamic>? body,
      }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        return await http.get(url, headers: headers);
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear session (for unauthorized errors)
  Future<void> clearSession() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('✅ Session cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
    }
  }

  // Clear all stored data
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('✅ All secure storage cleared');
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }

  // Create Astrologer Profile API
  Future<Map<String, dynamic>> createAstrologerProfile({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final url = Uri.parse('$baseUrl/api/astrologer/create');

    debugPrint('🚀 API Call: POST $url');
    debugPrint('📦 Payload: ${jsonEncode(payload)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('📡 Response token: ${token}');
      debugPrint('📡 Response URL: ${url}');
      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📡 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success response
        final responseData = jsonDecode(response.body);

        // Mark user as no longer new after successful profile creation
        await saveIsNewUser(false);

        return responseData;
      } else if (response.statusCode == 401) {
        // Unauthorized - clear session and throw error
        await clearSession();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        // Bad request - parse error message
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Invalid data provided';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Invalid data provided. Please check your information.');
        }
      } else if (response.statusCode >= 500) {
        // Server error
        throw Exception('Server error. Please try again later.');
      } else {
        // Other errors
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to create profile';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to create profile. Please try again.');
        }
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ Network Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to create profile. Please try again.');
    }
  }
}