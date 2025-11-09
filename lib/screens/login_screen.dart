import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidMobileNumber(String phone) {
    // Remove any spaces or special characters except +
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with +91 (with country code)
    if (cleanPhone.startsWith('+91')) {
      // Should have exactly 13 characters (+91 + 10 digits)
      return RegExp(r'^\+91[6-9]\d{9}$').hasMatch(cleanPhone);
    } else {
      // Without country code, should have exactly 10 digits starting with 6-9
      return RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone);
    }
  }

  String _formatPhoneNumber(String phone) {
    // Remove any spaces or special characters except +
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If already has +91, return as is
    if (cleanPhone.startsWith('+91')) {
      return cleanPhone;
    }

    // Add +91 prefix
    return '+91$cleanPhone';
  }

  Future<void> _handleContinue() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showErrorSnackBar('Please enter a phone number');
      return;
    }

    // Validate mobile number
    if (!_isValidMobileNumber(phone)) {
      _showErrorSnackBar('Please enter a valid 10-digit mobile number');
      return;
    }

    // Format the phone number with +91 if not present
    final formattedPhone = _formatPhoneNumber(phone);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(formattedPhone); // This now sends OTP

    if (!mounted) return;

    if (success) {
      // Navigate to OTP screen instead of KYC
      Navigator.pushNamed(
        context,
        '/otp',
        arguments: formattedPhone, // Pass formatted phone number to OTP screen
      );
    } else {
      _showErrorSnackBar(authProvider.error ?? "Failed to send OTP");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// Top 60% - Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.6,
            child: Image.asset(
              "assets/images/AstroIcon.png", // Your background image
              fit: BoxFit.cover,
            ),
          ),

          /// Gradient overlay for smooth transition
          Positioned(
            top: size.height * 0.55,
            left: 0,
            right: 0,
            height: size.height * 0.1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          /// Bottom section with content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Logo and Brand Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Small circular icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images/Karma.png", // Your small icon
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Brand name
                        Text(
                          "KarmaCalls",
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    /// Tagline
                    Text(
                      "Divine Solutions, Beyond Predictions",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Login Form Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2818),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1A3A2E).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Title
                          Text(
                            'Login/Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// Label
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Phone Number',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          /// Input Field
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A3A2E).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _phoneController,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Phone Number',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 15,
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          /// Continue Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4A7C59),
                                  Color(0xFF3A6B49),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3A6B49).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                'Continue',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}