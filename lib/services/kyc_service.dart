import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:math' show min;
import 'package:http_parser/http_parser.dart';

class KycService {
  // final String baseUrl = "http://100.27.221.127:3000/api/v1"; // Base URL
  //
  // /// Uploads a single document to /images/upload
  // Future<String> uploadDocument(File file, String token) async {
  //   try {
  //     final uri = Uri.parse("$baseUrl/images/upload");
  //     var request = http.MultipartRequest('POST', uri);
  //     request.headers['Authorization'] = 'Bearer $token';
  //     request.files.add(
  //       await http.MultipartFile.fromPath('file', file.path),
  //     );
  //
  //     var response = await request.send();
  //     debugPrint("✅ Logout API Response: ${response.statusCode}");
  //     debugPrint("✅ Logout file: ${file}");
  //     debugPrint("✅ Logout API token Body: ${token}");
  //     debugPrint("🔑 Authorization header: Bearer ${token.substring(0, 10)}...");
  //     debugPrint("📋 Request fields: ${request.headers}");
  //     debugPrint("📎 Request files: ${request.files.length}");
  //
  //     if (response.statusCode == 200) {
  //       final respStr = await response.stream.bytesToString();
  //       final data = jsonDecode(respStr);
  //       // Return the image URL from API
  //       return data['imageUrl'] ?? '';
  //     } else if (response.statusCode == 401) {
  //       throw Exception('Unauthorized: Invalid token');
  //     } else if (response.statusCode == 400) {
  //       throw Exception('Bad Request: No file uploaded');
  //     } else {
  //       final respStr = await response.stream.bytesToString();
  //       final data = jsonDecode(respStr);
  //       debugPrint("✅ Send OTP API Response Body: ${data}");
  //       throw Exception('Upload failed with status ${response.statusCode}');
  //     }
  //
  //   } catch (e) {
  //     debugPrint('KycService upload error: $e');x
  //     rethrow;
  //   }
  // }
  final String baseUrl = "http://98.91.1.108:8000"; // Base URL

  Future<String> uploadDocument(File file, String token) async {
    try {
      final uri = Uri.parse("$baseUrl/images/upload");
      var request = http.MultipartRequest('POST', uri);

      // Set Authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Get the file bytes and create multipart file with explicit content type
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file', // Field name must match API expectation
        fileBytes,
        filename: file.path.split('/').last,
        contentType: MediaType('image', 'jpeg'), // Explicitly set content type
      );

      request.files.add(multipartFile);

      debugPrint("📤 Uploading to: $uri");
      debugPrint("📎 File: ${file.path.split('/').last}");
      debugPrint("📦 File size: ${fileBytes.length} bytes");
      debugPrint("🔑 Token: ${token.substring(0, min(10, token.length))}...");
      debugPrint("📋 Headers: ${request.headers}");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("✅ Upload Response Status: ${response.statusCode}");
      debugPrint("📋 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl'] ?? '';
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid token');
      } else if (response.statusCode == 400) {
        throw Exception('Bad Request: ${response.body}');
      } else {
        throw Exception('Upload failed with status ${response.statusCode}: ${response.body}');
      }

    } catch (e) {
      debugPrint('❌ KycService upload error: $e');
      rethrow;
    }
  }
}
