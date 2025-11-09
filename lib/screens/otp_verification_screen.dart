import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;

  const OtpVerificationScreen({super.key, this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _resendTimer;
  int _resendCountdown = 45;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 45;
      _canResend = false;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpCode;

    if (otp.length != 6) {
      _showErrorSnackBar('Please enter the complete 6-digit OTP');
      return;
    }

    final String phoneNumber =
    ModalRoute.of(context)!.settings.arguments as String;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(phoneNumber, otp);

    if (!mounted) return;

    if (success != null &&
        success["token"] != null &&
        success["token"].length > 0) {
      if (success["is_new_user"] == true) {
        Navigator.pushNamedAndRemoveUntil(context, '/kyc', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else {
      _showErrorSnackBar(authProvider.error ?? "OTP verification failed");
      _clearOtpFields();
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    final String phoneNumber =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(phoneNumber);

    if (!mounted) return;

    if (success) {
      _showSuccessSnackBar('OTP sent successfully');
      _clearOtpFields();
      _startResendTimer();
    } else {
      _showErrorSnackBar(authProvider.error ?? "Failed to resend OTP");
    }
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto verify when all 6 digits are entered
    if (_otpCode.length == 6) {
      _handleVerifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String phoneNumber =
        widget.phoneNumber ??
            ModalRoute.of(context)?.settings.arguments as String? ??
            '';

    final isLoading = context.watch<AuthProvider>().isLoading;
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    // Enhanced responsive breakpoints
    final bool isVerySmallScreen = screenHeight < 600;
    final bool isSmallScreen = screenHeight < 700;
    final bool isNarrowScreen = screenWidth < 360;
    final bool isExtraWide = screenWidth > 600;

    // Dynamic sizing based on screen dimensions
    final double titleSize = isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 30);
    final double taglineSize = isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12);
    final double headingSize = isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 22);
    final double bodyTextSize = isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 14);
    final double phoneTextSize = isVerySmallScreen ? 13 : (isSmallScreen ? 14 : 16);

    // Calculate OTP box size responsively - using percentage of available width
    final double availableWidth = screenWidth * 0.80; // Use 80% of screen width for more margin
    final double totalHorizontalSpacing = (5 * 5) + 10; // 5 gaps of 5px + 1 extra gap of 10px after 3rd box
    final double otpBoxSize = ((availableWidth - totalHorizontalSpacing) / 6).clamp(32, 48);
    final double otpBoxHeight = (otpBoxSize * 1.15).clamp(45, 65);
    final double otpFontSize = (otpBoxSize * 0.4).clamp(16, 22);

    // Responsive spacing
    final double verticalSpacing = isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20);
    final double sectionSpacing = isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// Top 70% - Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.7,
            child: Image.asset(
              "assets/images/AstroIcon.png",
              fit: BoxFit.cover,
            ),
          ),

          /// Gradient overlay for smooth transition
          Positioned(
            top: size.height * 0.65,
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

          /// Main content
          SafeArea(
            child: Column(
              children: [
                /// Back button
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                /// Content section overlapping the image
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                                  "assets/images/Karma.png",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Brand name
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "KarmaCalls",
                                style: GoogleFonts.poppins(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isVerySmallScreen ? 2 : 4),

                        /// Tagline
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Divine Solutions, Beyond Predictions",
                            style: GoogleFonts.poppins(
                              fontSize: taglineSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        SizedBox(height: sectionSpacing),

                        /// OTP verification form section (Non-scrollable)
                        Center(
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              maxWidth: isExtraWide ? 500 : double.infinity,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06,
                              vertical: verticalSpacing,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Verify OTP',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: headingSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: verticalSpacing * 0.6),

                                Text(
                                  'We have sent a verification code to',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                    fontSize: bodyTextSize,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                SizedBox(height: 4),

                                // Phone number with proper overflow handling
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    ModalRoute.of(context)!.settings.arguments
                                    as String,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.lato(
                                      fontSize: phoneTextSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: sectionSpacing * 1.2),

                                /// OTP Input Fields - 6 digits in one row
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(6, (index) {
                                      // Add extra spacing after 3rd box for visual grouping
                                      return Container(
                                        width: otpBoxSize,
                                        height: otpBoxHeight,
                                        margin: EdgeInsets.only(
                                          right: index < 5 ? (index == 2 ? 10 : 5) : 0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _otpControllers[index],
                                          focusNode: _focusNodes[index],
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.lato(
                                            color: Colors.white,
                                            fontSize: otpFontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                              1,
                                            ),
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            counterText: '',
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onChanged: (value) =>
                                              _onOtpChanged(value, index),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                SizedBox(height: sectionSpacing),

                                /// Verify button
                                Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    maxWidth:
                                    isExtraWide ? 400 : double.infinity,
                                  ),
                                  height: isVerySmallScreen
                                      ? 46
                                      : (isSmallScreen ? 48 : 50),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4A7C59),
                                        Color(0xFF3A6B49),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF3A6B49,
                                        ).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                    isLoading ? null : _handleVerifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
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
                                      'Verify',
                                      style: GoogleFonts.lato(
                                        fontSize: bodyTextSize + 1,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: verticalSpacing),

                                /// Resend OTP with countdown timer
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      "Didn't receive code? ",
                                      style: GoogleFonts.lato(
                                        fontSize: bodyTextSize,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: (_canResend && !isLoading)
                                          ? _handleResendOtp
                                          : null,
                                      child: Text(
                                        "Resend",
                                        style: GoogleFonts.lato(
                                          fontSize: bodyTextSize,
                                          fontWeight: FontWeight.bold,
                                          color: _canResend
                                              ? const Color(0xFF4A7C59)
                                              : Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    if (!_canResend) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        "($_resendCountdown" "s)",
                                        style: GoogleFonts.lato(
                                          fontSize: bodyTextSize - 1,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: verticalSpacing * 0.8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}