import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/kyc_service.dart';
import 'auth_provider.dart';

class KycProvider extends ChangeNotifier {
  final KycService _kycService = KycService();

  Map<String, String> uploadedUrls = {
    'id_front': '',
    'id_back': '',
    'address_front': '',
    'address_back': '',
  };

  Map<String, bool> uploadStatus = {
    'id_front': false,
    'id_back': false,
    'address_front': false,
    'address_back': false,
  };

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  /// Uploads a document using token from AuthProvider
  Future<void> uploadDocument(File file, String documentType, String token) async {
    _isUploading = true;
    notifyListeners();

    try {
      final imageUrl = await _kycService.uploadDocument(file, token);
      uploadedUrls[documentType] = imageUrl;
      uploadStatus[documentType] = true;
      notifyListeners();
    } catch (e) {
      uploadStatus[documentType] = false;
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  bool get canSubmit => uploadStatus.values.every((uploaded) => uploaded);
}
