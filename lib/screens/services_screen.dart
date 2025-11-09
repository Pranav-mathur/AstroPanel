import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/global_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  // Track which section is expanded (only one at a time)
  String? _expandedSection;

  // Business Hours data
  Map<String, bool> _businessHours = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': false,
    'Sun': false,
  };

  // Time pickers (you can make these editable later)
  String _openTime = '9:00 AM';
  String _closeTime = '5:00 PM';

  // Categories data structure
  final Map<String, List<String>> _categoriesData = {
    'Astrologer': ['Love', 'Counsellor', 'Legal', 'Education'],
    'Healer': ['Reiki', 'Crystal Healing', 'Energy Healing'],
    'Tarot': ['Love Reading', 'Career Reading', 'Life Path'],
    'Vastu': ['Home Vastu', 'Office Vastu', 'Land Vastu'],
    'Numerologists': ['Name Numerology', 'Birth Number', 'Destiny Number'],
  };

  // Selected categories and subcategories
  Map<String, List<String>> _selectedCategories = {};

  // Skills and Languages lists
  List<String> _skills = [];
  List<String> _languages = [];

  // Consultation fee controllers
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _audioController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  bool _isSaving = false;

  // Check if all required fields are filled
  bool get _isFormValid {
    // Check if at least one working day is selected
    final hasWorkingDays = _businessHours.values.any((isOpen) => isOpen);

    // Check if at least one category with subcategories is selected
    final hasCategories = _selectedCategories.isNotEmpty &&
        _selectedCategories.values.any((subCats) => subCats.isNotEmpty);

    // Check if at least one skill is added
    final hasSkills = _skills.isNotEmpty;

    // Check if at least one language is added
    final hasLanguages = _languages.isNotEmpty;

    // Check if at least one consultation fee is entered
    final hasConsultationFees =
        _messageController.text.trim().isNotEmpty ||
            _audioController.text.trim().isNotEmpty ||
            _videoController.text.trim().isNotEmpty;

    return hasWorkingDays && hasCategories && hasSkills && hasLanguages && hasConsultationFees;
  }

  @override
  void initState() {
    super.initState();
    _loadExistingData();

    // Add listeners to text controllers to rebuild when text changes
    _messageController.addListener(() => setState(() {}));
    _audioController.addListener(() => setState(() {}));
    _videoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _loadExistingData() async {
    final globalProvider = Provider.of<GlobalProvider>(context, listen: false);
    final authService = AuthService();

    // Load phone number from secure storage and save to GlobalProvider
    final phoneNumber = await authService.getPhoneNumber();
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      globalProvider.setPhone(phoneNumber);
      debugPrint("📱 Phone number loaded from secure storage: $phoneNumber");
    }

    // Load working days
    final workingDays = globalProvider.getWorkingDays();
    if (workingDays.isNotEmpty) {
      setState(() {
        _businessHours = {
          'Sun': workingDays.contains(0),
          'Mon': workingDays.contains(1),
          'Tue': workingDays.contains(2),
          'Wed': workingDays.contains(3),
          'Thu': workingDays.contains(4),
          'Fri': workingDays.contains(5),
          'Sat': workingDays.contains(6),
        };
      });
    }

    // Load categories
    final categories = globalProvider.getCategories();
    if (categories.isNotEmpty) {
      setState(() {
        _selectedCategories = {};
        for (var category in categories) {
          final name = category['name'] as String;
          final subCategories = List<String>.from(category['subCategories'] as List);
          _selectedCategories[name] = subCategories;
        }
      });
    }

    // Load skills
    final skills = globalProvider.getSkills();
    if (skills.isNotEmpty) {
      setState(() {
        _skills = skills;
      });
    }

    // Load languages
    final languages = globalProvider.getLanguagesKnown();
    if (languages.isNotEmpty) {
      setState(() {
        _languages = languages;
      });
    }

    // Load consultation fees
    final consultationFee = globalProvider.getConsultationFee();
    if (consultationFee != null) {
      _messageController.text = consultationFee['message']?.toString() ?? '';
      _audioController.text = consultationFee['audio']?.toString() ?? '';
      _videoController.text = consultationFee['video']?.toString() ?? '';
    }
  }

  void _toggleSection(String section) {
    setState(() {
      if (_expandedSection == section) {
        _expandedSection = null;
      } else {
        _expandedSection = section;
      }
    });
  }

  void _toggleDay(String day) {
    setState(() {
      _businessHours[day] = !_businessHours[day]!;
    });
  }

  void _showCategoriesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoriesBottomSheet(
        categoriesData: _categoriesData,
        selectedCategories: Map.from(_selectedCategories),
        onSave: (selected) {
          setState(() {
            _selectedCategories = selected;
          });
        },
      ),
    );
  }

  void _showAddItemDialog(String type) {
    final TextEditingController controller = TextEditingController();
    final String title = type == 'skill' ? 'Add Skill' : 'Add Language';
    final String hint = type == 'skill' ? 'Enter skill name' : 'Enter language name';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.lato(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                setState(() {
                  if (type == 'skill' && _skills.length < 6 && !_skills.contains(value)) {
                    _skills.add(value);
                  } else if (type == 'language' && _languages.length < 6 && !_languages.contains(value)) {
                    _languages.add(value);
                  }
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Add',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeItem(String type, String item) {
    setState(() {
      if (type == 'skill') {
        _skills.remove(item);
      } else if (type == 'language') {
        _languages.remove(item);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$item removed successfully'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final globalProvider = Provider.of<GlobalProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Save working days
      final List<int> workingDays = [];
      final dayMap = {
        'Sun': 0,
        'Mon': 1,
        'Tue': 2,
        'Wed': 3,
        'Thu': 4,
        'Fri': 5,
        'Sat': 6,
      };

      _businessHours.forEach((day, isOpen) {
        if (isOpen) {
          workingDays.add(dayMap[day]!);
        }
      });

      globalProvider.setWorkingDays(workingDays);

      // Save categories
      final List<Map<String, dynamic>> categoriesList = [];
      _selectedCategories.forEach((categoryName, subCategories) {
        if (subCategories.isNotEmpty) {
          categoriesList.add({
            'name': categoryName,
            'subCategories': subCategories,
          });
        }
      });

      globalProvider.setCategories(categoriesList);

      // Save skills
      globalProvider.setSkills(_skills);

      // Save languages
      globalProvider.setLanguagesKnown(_languages);

      // Save consultation fees
      final messageFee = double.tryParse(_messageController.text.trim()) ?? 0;
      final audioFee = double.tryParse(_audioController.text.trim()) ?? 0;
      final videoFee = double.tryParse(_videoController.text.trim()) ?? 0;

      globalProvider.setConsultationFee(
        message: messageFee,
        audio: audioFee,
        video: videoFee,
      );

      debugPrint("=== 💾 SERVICES DATA SAVED ===");
      debugPrint("📅 Working Days: $workingDays");
      debugPrint("📂 Categories: $categoriesList");
      debugPrint("🎯 Skills: $_skills");
      debugPrint("🌍 Languages: $_languages");
      debugPrint("💰 Consultation Fees: {message: $messageFee, audio: $audioFee, video: $videoFee}");
      debugPrint("============================");

      // Get complete API payload
      final apiPayload = globalProvider.getAstrologerApiPayload();
      debugPrint("📋 Complete Astrologer API Payload:");
      debugPrint(jsonEncode(apiPayload));
      debugPrint("================================================");

      // Make API call using AuthProvider
      debugPrint("🚀 Making API call to create astrologer profile...");
      final response = await authProvider.createAstrologerProfile(apiPayload);

      if (response == null) {
        // Error occurred, authProvider.error will have the message
        throw Exception(authProvider.error ?? 'Failed to create profile');
      }

      debugPrint("✅ API Response: $response");

      setState(() {
        _isSaving = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Profile created successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate to home page after a short delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home', // Replace with your actual home route name
                (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      debugPrint("❌ Error saving profile: ${e.toString()}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Services',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Business Hours Section
                  _buildBusinessHoursSection(),
                  const SizedBox(height: 12),

                  // Categories Section
                  _buildCategoriesSection(),
                  const SizedBox(height: 12),

                  // Skills Section
                  _buildSkillsSection(),
                  const SizedBox(height: 12),

                  // Languages Section
                  _buildLanguagesSection(),
                  const SizedBox(height: 12),

                  // Consultations Section
                  _buildConsultationsSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isSaving || !_isFormValid) ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid
                      ? const Color(0xFF81C784)
                      : const Color(0xFF065922).withOpacity(0.3),
                  disabledBackgroundColor: const Color(0xFF3A6B49).withOpacity(0.3),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Saving...',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                    : Text(
                  'Save',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _isFormValid
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursSection() {
    final isExpanded = _expandedSection == 'business_hours';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => _toggleSection('business_hours'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Business Hours',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                children: _businessHours.keys.map((day) {
                  final isOpen = _businessHours[day]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Day name
                        SizedBox(
                          width: 36,
                          child: Text(
                            day,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        // Open/Close text (reduced width)
                        SizedBox(
                          width: 36,
                          child: Text(
                            isOpen ? 'Open' : 'Close',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),

                        // Toggle switch
                        Transform.scale(
                          scale: 0.65,
                          child: Switch(
                            value: isOpen,
                            onChanged: (value) => _toggleDay(day),
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF4CAF50),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey[400],
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Time fields (always visible)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _openTime,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _closeTime,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return InkWell(
      onTap: _showCategoriesBottomSheet,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    final isExpanded = _expandedSection == 'skills';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => _toggleSection('skills'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Skills',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skills grid (3 columns, 2 rows max)
                  if (_skills.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 12,
                      children: _skills.map((skill) {
                        return SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 3,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Text(
                                  skill,
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removeItem('skill', skill),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  if (_skills.isNotEmpty) const SizedBox(height: 16),

                  // Add New button
                  if (_skills.length < 6)
                    GestureDetector(
                      onTap: () => _showAddItemDialog('skill'),
                      child: Text(
                        '+Add New',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
    final isExpanded = _expandedSection == 'languages';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => _toggleSection('languages'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Languages',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Languages grid (3 columns, 2 rows max)
                  if (_languages.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 12,
                      children: _languages.map((language) {
                        return SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 3,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Text(
                                  language,
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removeItem('language', language),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  if (_languages.isNotEmpty) const SizedBox(height: 16),

                  // Add New button
                  if (_languages.length < 6)
                    GestureDetector(
                      onTap: () => _showAddItemDialog('language'),
                      child: Text(
                        '+Add New',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsultationsSection() {
    final isExpanded = _expandedSection == 'consultations';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => _toggleSection('consultations'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Consultations',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Fee Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Message',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _messageController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: '₹ 0',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 15,
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Audio Call Fee Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Audio Call',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _audioController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: '₹ 0',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 15,
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Video Call Fee Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Video Call',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _videoController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: '₹ 0',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 15,
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderSection(String title) {
    final isExpanded = _expandedSection == title.toLowerCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleSection(title.toLowerCase()),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Categories Bottom Sheet Widget
class _CategoriesBottomSheet extends StatefulWidget {
  final Map<String, List<String>> categoriesData;
  final Map<String, List<String>> selectedCategories;
  final Function(Map<String, List<String>>) onSave;

  const _CategoriesBottomSheet({
    required this.categoriesData,
    required this.selectedCategories,
    required this.onSave,
  });

  @override
  State<_CategoriesBottomSheet> createState() => _CategoriesBottomSheetState();
}

class _CategoriesBottomSheetState extends State<_CategoriesBottomSheet> {
  late Map<String, List<String>> _tempSelected;
  String _selectedCategory = 'Astrologer';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempSelected = Map.from(widget.selectedCategories);

    // Initialize empty lists for categories not yet selected
    widget.categoriesData.keys.forEach((category) {
      if (!_tempSelected.containsKey(category)) {
        _tempSelected[category] = [];
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSubcategory(String category, String subcategory) {
    setState(() {
      if (_tempSelected[category]!.contains(subcategory)) {
        _tempSelected[category]!.remove(subcategory);
      } else {
        _tempSelected[category]!.add(subcategory);
      }
    });
  }

  void _handleSave() {
    // Remove categories with no subcategories selected
    final filteredSelected = Map<String, List<String>>.fromEntries(
      _tempSelected.entries.where((entry) => entry.value.isNotEmpty),
    );

    widget.onSave(filteredSelected);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Categories & Subcategories',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.lato(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search category or subcategory',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                  suffixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Content area with categories and subcategories
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories list (left side) - Increased width
                Container(
                  width: MediaQuery.of(context).size.width * 0.42,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: widget.categoriesData.keys.map((category) {
                      final isSelected = _selectedCategory == category;
                      final hasSelections = _tempSelected[category]?.isNotEmpty ?? false;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green[50] : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: hasSelections ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF4CAF50) : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Subcategories list (right side)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    children: widget.categoriesData[_selectedCategory]!.map((subcategory) {
                      final isChecked = _tempSelected[_selectedCategory]?.contains(subcategory) ?? false;

                      return InkWell(
                        onTap: () => _toggleSubcategory(_selectedCategory, subcategory),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isChecked ? const Color(0xFF4CAF50) : Colors.transparent,
                                  border: Border.all(
                                    color: isChecked ? const Color(0xFF4CAF50) : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: isChecked
                                    ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  subcategory,
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Save button - Minimal bottom padding
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}