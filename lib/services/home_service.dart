import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeService {
  final String baseUrl = 'http://98.91.1.108:8000/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Get auth token from secure storage
  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'token');
  }

  // Fetch user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/astrologer/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  // Fetch bookings with date range
  Future<Map<String, dynamic>> getBookings({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final uri = Uri.parse('$baseUrl/booking/astrologer').replace(
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  // Update astrologer profile
  Future<Map<String, dynamic>> updateAstrologerProfile({
    required Map<String, dynamic> body,
  }) async {
    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/astrologer/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      debugPrint('📡 Response token: ${token}');
      debugPrint('📡 Response URL: ${Uri.parse('$baseUrl/astrologer/update')}');
      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Helper to get this month's date range
  static DateTimeRange getThisMonthRange() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: firstDay, end: lastDay);
  }

  // Helper to format date range for display (e.g., "1 Nov - 24 Nov")
  static String formatDateRange(DateTime start, DateTime end) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]}';
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}