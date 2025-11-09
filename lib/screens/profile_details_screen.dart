import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../providers/auth_provider.dart';
import '../providers/global_provider.dart';
import '../providers/kyc_provider.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isUploadingImage = false;
  bool _isSaving = false;

  // Store uploaded display images with their file names and URLs
  List<Map<String, String>> uploadedImages = [];

  // Check if all required fields are filled
  bool get _isFormValid {
    return _profileNameController.text.trim().isNotEmpty &&
        uploadedImages.isNotEmpty &&
        _aboutMeController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadExistingData();

    // Add listeners to rebuild UI when text changes
    _profileNameController.addListener(() {
      setState(() {});
    });

    _aboutMeController.addListener(() {
      setState(() {});
    });
  }

  void _loadExistingData() {
    final globalProvider = Provider.of<GlobalProvider>(context, listen: false);

    // Load profile name
    final profileName = globalProvider.getProfileName();
    if (profileName != null) {
      _profileNameController.text = profileName;
    }

    // Load about me
    final aboutMe = globalProvider.getAboutMe();
    if (aboutMe != null) {
      _aboutMeController.text = aboutMe;
    }

    // Load display image if exists
    final displayImage = globalProvider.getDisplayImage();
    if (displayImage != null) {
      setState(() {
        uploadedImages = [
          {
            'fileName': 'Display Image',
            'url': displayImage,
          }
        ];
      });
    }
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _uploadDisplayImages() async {
    if (_isUploadingImage) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final file = File(image.path);
        final fileName = path.basename(image.path);

        // Get token from AuthProvider
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        if (token == null) {
          setState(() {
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // Upload document via KycProvider (reusing for portfolio images)
        // Using a custom document type for portfolio images
        final documentType = 'portfolio_${DateTime.now().millisecondsSinceEpoch}';
        await Provider.of<KycProvider>(context, listen: false)
            .uploadDocument(file, documentType, token);

        // Get the uploaded URL from KycProvider
        final imageUrl = Provider.of<KycProvider>(context, listen: false).uploadedUrls[documentType];

        if (imageUrl != null) {
          setState(() {
            uploadedImages.add({
              'fileName': fileName,
              'url': imageUrl,
            });
            _isUploadingImage = false;
          });

          // Save images globally (extract URLs only)
          final imageUrls = uploadedImages.map((img) => img['url']!).toList();
          Provider.of<GlobalProvider>(context, listen: false)
              .setPortfolioImages(imageUrls);

          debugPrint("=== 📸 PORTFOLIO IMAGE UPLOADED ===");
          debugPrint("📄 File Name: $fileName");
          debugPrint("🔗 URL: $imageUrl");
          debugPrint("💾 Total Images: ${uploadedImages.length}");
          debugPrint("===================================");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload failed - no URL returned'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _viewImage(String fileName, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                fileName,
                style: GoogleFonts.lato(fontSize: 16),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.file(
                File(imageUrl),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 100);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      uploadedImages.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSave() async {
    // Validate required fields with specific error messages
    if (_profileNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Please enter your profile name'),
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
      return;
    }

    if (uploadedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Please upload at least one display image'),
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
      return;
    }

    if (_aboutMeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Please tell us about yourself'),
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
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Simulate network delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 800));

      final globalProvider = Provider.of<GlobalProvider>(context, listen: false);

      // Save profile name
      globalProvider.setProfileName(_profileNameController.text.trim());

      // Save display image (first image as primary display image)
      if (uploadedImages.isNotEmpty) {
        globalProvider.setDisplayImage(uploadedImages.first['url']!);
      }

      // Save about me
      globalProvider.setAboutMe(_aboutMeController.text.trim());

      // Print debug info
      debugPrint("=== 💾 PROFILE DATA SAVED ===");
      debugPrint("👤 Profile Name: ${globalProvider.getProfileName()}");
      debugPrint("🖼️ Display Image: ${globalProvider.getDisplayImage()}");
      debugPrint("📝 About Me: ${globalProvider.getAboutMe()}");
      debugPrint("============================");

      final apiPayload = globalProvider.getAstrologerApiPayload();
      debugPrint("📋 Complete Astrologer API Payload:");
      debugPrint(jsonEncode(apiPayload));
      debugPrint("================================================");

      setState(() {
        _isSaving = false;
      });

      // Show success message with animation
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
                child: Text('Profile details saved successfully!'),
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

      // Optional: Navigate to next screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushNamed(context, '/services');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Save failed: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
          'Profile Details',
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
          // Header Section with Icon
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                // App Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/Karma.png', // Replace with your actual asset path
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon if image not found
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade300, Colors.purple.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile Details',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Form Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Name Section
                  Text(
                    'Profile Name',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _profileNameController,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter Profile Name',
                        hintStyle: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Display Image Section
                  Text(
                    'Display Image',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Upload button
                          GestureDetector(
                            onTap: _isUploadingImage ? null : _uploadDisplayImages,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    uploadedImages.isEmpty
                                        ? 'Upload Display Image'
                                        : 'Upload Display Image(s)',
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _isUploadingImage ? Colors.grey[400] : Colors.black,
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: _isUploadingImage
                                        ? Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: CircularProgressIndicator(
                                        color: Colors.green,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Icon(Icons.upload, color: Colors.green.shade400, size: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Uploaded images list
                          if (uploadedImages.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ...uploadedImages.asMap().entries.map((entry) {
                              int index = entry.key;
                              String fileName = entry.value['fileName'] ?? '';
                              String imageUrl = entry.value['url'] ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileName,
                                            style: GoogleFonts.lato(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.cloud_done,
                                                size: 12,
                                                color: Colors.blue[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Uploaded',
                                                style: GoogleFonts.lato(
                                                  fontSize: 11,
                                                  color: Colors.blue[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _viewImage(fileName, imageUrl),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        child: Text(
                                          'View',
                                          style: GoogleFonts.lato(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        child: Text(
                                          'Remove',
                                          style: GoogleFonts.lato(
                                            fontSize: 12,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 16),

                          // Helper text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[600],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You can upload multiple images one at a time',
                                      style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[600],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'These images will appear in your profile card',
                                      style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About Me Section
                  Text(
                    'About me',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _aboutMeController,
                      maxLines: 8,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'About me',
                        hintStyle: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isFormValid && !_isSaving
                    ? [
                  BoxShadow(
                    color: const Color(0xFF3A6B49).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: (_isSaving || !_isFormValid) ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid
                      ? const Color(0xFF4CAF50)  // Bright green when enabled (matching screenshot)
                      : const Color(0xFFE0E0E0),  // Light gray when disabled
                  disabledBackgroundColor: _isFormValid
                      ? const Color(0xFF4CAF50).withOpacity(0.7)  // Slightly dimmed when saving
                      : const Color(0xFFE0E0E0),  // Light gray when form incomplete
                  foregroundColor: Colors.white,
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
                    color: _isFormValid ? Colors.white : const Color(0xFFBDBDBD),  // Gray text when disabled
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