import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GlobalProvider extends ChangeNotifier {
  Map<String, dynamic> globalData = {};

  // ==================== Constructor ====================
  GlobalProvider() {
    // Default experience value
    globalData['experience'] = 1;
  }

  // ==================== Basic Methods ====================
  void setValue(String key, dynamic value) {
    globalData[key] = value;
    notifyListeners();
  }

  dynamic getValue(String key) => globalData[key];

  // ==================== Profile Basic Info ====================
  void setProfileName(String name) {
    globalData['profileName'] = name;
    notifyListeners();
  }

  String? getProfileName() => globalData['profileName'] as String?;

  void setPhone(String phone) {
    globalData['phone'] = phone;
    notifyListeners();
  }

  String? getPhone() => globalData['phone'] as String?;

  void setDisplayImage(String imageUrl) {
    globalData['displayImage'] = imageUrl;
    notifyListeners();
  }

  String? getDisplayImage() => globalData['displayImage'] as String?;

  void setAboutMe(String about) {
    globalData['aboutMe'] = about;
    notifyListeners();
  }

  String? getAboutMe() => globalData['aboutMe'] as String?;

  // ==================== Experience (Default: 1) ====================
  void setExperience(int years) {
    globalData['experience'] = years;
    notifyListeners();
  }

  int getExperience() => (globalData['experience'] as int?) ?? 1;

  // ==================== Total Reviews ====================
  void setTotalReviews(int reviews) {
    globalData['totalReviews'] = reviews;
    notifyListeners();
  }

  int? getTotalReviews() => globalData['totalReviews'] as int?;

  // ==================== Skills Methods ====================
  void setSkills(List<String> skills) {
    globalData['skills'] = skills;
    notifyListeners();
  }

  List<String> getSkills() {
    if (globalData['skills'] == null) return <String>[];
    return List<String>.from(globalData['skills'] as List);
  }

  void addSkill(String skill) {
    if (globalData['skills'] == null) {
      globalData['skills'] = <String>[];
    }
    (globalData['skills'] as List<String>).add(skill);
    notifyListeners();
  }

  void removeSkill(String skill) {
    (globalData['skills'] as List<String>?)?.remove(skill);
    notifyListeners();
  }

  // ==================== Category Methods ====================
  void setCategories(List<Map<String, dynamic>> categories) {
    globalData['category'] = categories;
    notifyListeners();
  }

  List<Map<String, dynamic>> getCategories() {
    if (globalData['category'] == null) {
      return <Map<String, dynamic>>[];
    }

    if (globalData['category'] is List<Map<String, dynamic>>) {
      return globalData['category'] as List<Map<String, dynamic>>;
    } else if (globalData['category'] is List) {
      final categories = List<Map<String, dynamic>>.from(
        (globalData['category'] as List).map(
              (item) => item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map),
        ),
      );
      globalData['category'] = categories;
      return categories;
    }

    return <Map<String, dynamic>>[];
  }

  void addCategory({
    required String name,
    required List<String> subCategories,
  }) {
    if (globalData['category'] == null) {
      globalData['category'] = <Map<String, dynamic>>[];
    }

    final category = {
      'name': name,
      'subCategories': subCategories,
    };

    (globalData['category'] as List<Map<String, dynamic>>).add(category);
    notifyListeners();
  }

  void removeCategory(String categoryName) {
    (globalData['category'] as List<Map<String, dynamic>>?)
        ?.removeWhere((category) => category['name'] == categoryName);
    notifyListeners();
  }

  void updateCategory({
    required String categoryName,
    List<String>? subCategories,
    String? newName,
  }) {
    final categories = globalData['category'] as List<Map<String, dynamic>>?;
    if (categories == null) return;

    final index = categories.indexWhere((c) => c['name'] == categoryName);
    if (index != -1) {
      if (newName != null) categories[index]['name'] = newName;
      if (subCategories != null) {
        categories[index]['subCategories'] = subCategories;
      }
      notifyListeners();
    }
  }

  void clearCategories() {
    globalData['category'] = [];
    notifyListeners();
  }

  // ==================== Languages Known Methods ====================
  void setLanguagesKnown(List<String> languages) {
    globalData['languagesKnown'] = languages;
    notifyListeners();
  }

  List<String> getLanguagesKnown() {
    if (globalData['languagesKnown'] == null) return <String>[];
    return List<String>.from(globalData['languagesKnown'] as List);
  }

  void addLanguage(String language) {
    if (globalData['languagesKnown'] == null) {
      globalData['languagesKnown'] = <String>[];
    }
    (globalData['languagesKnown'] as List<String>).add(language);
    notifyListeners();
  }

  void removeLanguage(String language) {
    (globalData['languagesKnown'] as List<String>?)?.remove(language);
    notifyListeners();
  }

  // ==================== KYC Documents Methods ====================
  void setIdProofFrontImage(String imageUrl) {
    globalData['idProofFrontImage'] = imageUrl;
    notifyListeners();
  }

  String? getIdProofFrontImage() => globalData['idProofFrontImage'] as String?;

  void setIdProofBackImage(String imageUrl) {
    globalData['idProofBackImage'] = imageUrl;
    notifyListeners();
  }

  String? getIdProofBackImage() => globalData['idProofBackImage'] as String?;

  void setAddressProofFrontImage(String imageUrl) {
    globalData['addressProofFrontImage'] = imageUrl;
    notifyListeners();
  }

  String? getAddressProofFrontImage() =>
      globalData['addressProofFrontImage'] as String?;

  void setAddressProofBackImage(String imageUrl) {
    globalData['addressProofBackImage'] = imageUrl;
    notifyListeners();
  }

  String? getAddressProofBackImage() =>
      globalData['addressProofBackImage'] as String?;

  void setIdProof({
    required String frontImageUrl,
    required String backImageUrl,
  }) {
    globalData['idProofFrontImage'] = frontImageUrl;
    globalData['idProofBackImage'] = backImageUrl;
    notifyListeners();
  }

  void setAddressProof({
    required String frontImageUrl,
    required String backImageUrl,
  }) {
    globalData['addressProofFrontImage'] = frontImageUrl;
    globalData['addressProofBackImage'] = backImageUrl;
    notifyListeners();
  }

  // ==================== Working Days Methods ====================
  void setWorkingDays(List<int> days) {
    globalData['workingDays'] = days;
    notifyListeners();
  }

  List<int> getWorkingDays() {
    if (globalData['workingDays'] == null) return <int>[];
    return List<int>.from(globalData['workingDays'] as List);
  }

  void addWorkingDay(int day) {
    if (globalData['workingDays'] == null) {
      globalData['workingDays'] = <int>[];
    }
    if (!getWorkingDays().contains(day)) {
      (globalData['workingDays'] as List<int>).add(day);
      notifyListeners();
    }
  }

  void removeWorkingDay(int day) {
    (globalData['workingDays'] as List<int>?)?.remove(day);
    notifyListeners();
  }

  // ==================== Consultation Fee Methods ====================
  void setConsultationFee({
    required double message,
    required double audio,
    required double video,
  }) {
    globalData['consultationFee'] = {
      'message': message,
      'audio': audio,
      'video': video,
    };
    notifyListeners();
  }

  Map<String, dynamic>? getConsultationFee() {
    return globalData['consultationFee'] as Map<String, dynamic>?;
  }

  void updateConsultationFee({
    double? message,
    double? audio,
    double? video,
  }) {
    if (globalData['consultationFee'] == null) {
      globalData['consultationFee'] = <String, dynamic>{};
    }

    final fees = globalData['consultationFee'] as Map<String, dynamic>;
    if (message != null) fees['message'] = message;
    if (audio != null) fees['audio'] = audio;
    if (video != null) fees['video'] = video;

    notifyListeners();
  }

  // ==================== Legacy Support Methods ====================
  void setBusinessDetails({required String name}) {
    globalData['name'] = name;
    notifyListeners();
  }

  void setPortfolioImages(List<String> images) {
    globalData['portfolio_images'] = images;
    notifyListeners();
  }

  void addPortfolioImage(String imageUrl) {
    if (globalData['portfolio_images'] == null) {
      globalData['portfolio_images'] = <String>[];
    }
    (globalData['portfolio_images'] as List<String>).add(imageUrl);
    notifyListeners();
  }

  void removePortfolioImage(String imageUrl) {
    (globalData['portfolio_images'] as List<String>?)?.remove(imageUrl);
    notifyListeners();
  }

  void setAddress({
    required String building,
    required String street,
    required String city,
    required String state,
    required String pincode,
    required String mobile,
  }) {
    globalData['address'] = {
      'building': building,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'mobile': mobile,
    };
    notifyListeners();
  }

  Map<String, dynamic>? getAddress() {
    return globalData['address'] as Map<String, dynamic>?;
  }

  void updateAddressField(String field, String value) {
    if (globalData['address'] == null) {
      globalData['address'] = <String, dynamic>{};
    }
    (globalData['address'] as Map<String, dynamic>)[field] = value;
    notifyListeners();
  }

  void setLocation({required double longitude, required double latitude}) {
    globalData['location'] = {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    };
    notifyListeners();
  }

  void setKycAddressProof({
    required String frontImageUrl,
    required String backImageUrl,
  }) {
    globalData['kyc_address_proof_front'] = frontImageUrl;
    globalData['kyc_address_proof_back'] = backImageUrl;
    notifyListeners();
  }

  void setKycAddressProofFront(String imageUrl) {
    globalData['kyc_address_proof_front'] = imageUrl;
    notifyListeners();
  }

  void setKycAddressProofBack(String imageUrl) {
    globalData['kyc_address_proof_back'] = imageUrl;
    notifyListeners();
  }

  void setIdProofFront(String imageUrl) {
    globalData['id_proof_front'] = imageUrl;
    notifyListeners();
  }

  void setIdProofBack(String imageUrl) {
    globalData['id_proof_back'] = imageUrl;
    notifyListeners();
  }

  // ==================== Validation Methods ====================
  bool isAstrologerDataComplete() {
    final requiredFields = [
      'profileName',
      'phone',
      'displayImage',
      'aboutMe',
      'experience',
      'skills',
      'category',
      'languagesKnown',
      'idProofFrontImage',
      'idProofBackImage',
      'addressProofFrontImage',
      'addressProofBackImage',
      'workingDays',
      'consultationFee',
    ];

    for (String field in requiredFields) {
      if (globalData[field] == null) return false;
    }

    if ((globalData['skills'] as List?)?.isEmpty ?? true) return false;
    if ((globalData['category'] as List?)?.isEmpty ?? true) return false;
    if ((globalData['languagesKnown'] as List?)?.isEmpty ?? true) return false;
    if ((globalData['workingDays'] as List?)?.isEmpty ?? true) return false;

    final consultationFee =
    globalData['consultationFee'] as Map<String, dynamic>?;
    if (consultationFee == null ||
        consultationFee['message'] == null ||
        consultationFee['audio'] == null ||
        consultationFee['video'] == null) {
      return false;
    }

    return true;
  }

  List<String> getAstrologerMissingFields() {
    final requiredFields = [
      'profileName',
      'phone',
      'displayImage',
      'aboutMe',
      'experience',
      'skills',
      'category',
      'languagesKnown',
      'idProofFrontImage',
      'idProofBackImage',
      'addressProofFrontImage',
      'addressProofBackImage',
      'workingDays',
      'consultationFee',
    ];

    List<String> missingFields = [];
    for (String field in requiredFields) {
      if (globalData[field] == null) missingFields.add(field);
    }

    if ((globalData['skills'] as List?)?.isEmpty ?? true) {
      missingFields.add('skills (empty)');
    }
    if ((globalData['category'] as List?)?.isEmpty ?? true) {
      missingFields.add('category (empty)');
    }
    if ((globalData['languagesKnown'] as List?)?.isEmpty ?? true) {
      missingFields.add('languagesKnown (empty)');
    }
    if ((globalData['workingDays'] as List?)?.isEmpty ?? true) {
      missingFields.add('workingDays (empty)');
    }

    return missingFields;
  }

  // ==================== API Methods ====================
  Map<String, dynamic> getAstrologerApiPayload() {
    return {
      'profileName': globalData['profileName'],
      'phone': globalData['phone'],
      'displayImage': globalData['displayImage'],
      'aboutMe': globalData['aboutMe'],
      'experience': globalData['experience'],
      'skills': globalData['skills'],
      'category': globalData['category'],
      'languagesKnown': globalData['languagesKnown'],
      'totalReviews': globalData['totalReviews'] ?? 0,
      'idProofFrontImage': globalData['idProofFrontImage'],
      'idProofBackImage': globalData['idProofBackImage'],
      'addressProofFrontImage': globalData['addressProofFrontImage'],
      'addressProofBackImage': globalData['addressProofBackImage'],
      'workingDays': globalData['workingDays'],
      'consultationFee': globalData['consultationFee'],
    };
  }

  Future<bool> submitAstrologerData({
    required String apiUrl,
    Map<String, String>? headers,
  }) async {
    if (!isAstrologerDataComplete()) {
      final missing = getAstrologerMissingFields();
      throw Exception(
          'Astrologer data is incomplete. Missing fields: ${missing.join(', ')}');
    }

    final payload = getAstrologerApiPayload();
    final defaultHeaders = {'Content-Type': 'application/json'};
    if (headers != null) defaultHeaders.addAll(headers);

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: defaultHeaders,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) return true;

    throw Exception(
        'API call failed with status: ${response.statusCode}, body: ${response.body}');
  }

  // ==================== Utility Methods ====================
  void clearData() {
    globalData.clear();
    globalData['experience'] = 1; // Reapply default on clear
    notifyListeners();
  }

  void clearField(String key) {
    globalData.remove(key);
    notifyListeners();
  }

  Map<String, dynamic> getAstrologerDataSummary() {
    return {
      'profileName': globalData['profileName'],
      'phone': globalData['phone'],
      'displayImage_set': globalData['displayImage'] != null,
      'aboutMe_length': (globalData['aboutMe'] as String?)?.length ?? 0,
      'experience': getExperience(),
      'skills_count': (globalData['skills'] as List?)?.length ?? 0,
      'category_count': (globalData['category'] as List?)?.length ?? 0,
      'languages_count': (globalData['languagesKnown'] as List?)?.length ?? 0,
      'totalReviews': globalData['totalReviews'] ?? 0,
      'kyc_docs_count': [
        globalData['idProofFrontImage'],
        globalData['idProofBackImage'],
        globalData['addressProofFrontImage'],
        globalData['addressProofBackImage'],
      ].where((doc) => doc != null).length,
      'working_days_count': (globalData['workingDays'] as List?)?.length ?? 0,
      'consultation_fee_set': globalData['consultationFee'] != null,
      'is_complete': isAstrologerDataComplete(),
    };
  }

  void printCurrentData() {
    if (kDebugMode) {
      print('Current Global Data:');
      print(jsonEncode(globalData));
      print('\nAstrologer Data Summary:');
      print(jsonEncode(getAstrologerDataSummary()));
    }
  }

  Map<String, dynamic> getAllData() {
    return globalData;
  }
}
