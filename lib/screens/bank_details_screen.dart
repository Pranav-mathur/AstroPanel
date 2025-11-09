import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/home_service.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // Call API to get astrologer profile
      final homeService = HomeService();
      final response = await homeService.getUserProfile();

      // Check if bankDetails exists in response
      if (response.containsKey('bankDetails')) {
        final bankDetails = response['bankDetails'] as Map<String, dynamic>?;

        if (bankDetails != null) {
          setState(() {
            _accountHolderController.text = bankDetails['accountHolderName'] ?? '';
            _bankNameController.text = bankDetails['bankName'] ?? '';
            _accountNumberController.text = bankDetails['accountNumber'] ?? '';
            _ifscCodeController.text = bankDetails['ifscCode'] ?? '';
          });
        }
      }
      // If no bankDetails field, leave fields empty - no error
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _canSubmit {
    return _accountHolderController.text.trim().isNotEmpty &&
        _bankNameController.text.trim().isNotEmpty &&
        _accountNumberController.text.trim().isNotEmpty &&
        _ifscCodeController.text.trim().isNotEmpty &&
        _isValidIFSC(_ifscCodeController.text.trim()) &&
        _isValidAccountNumber(_accountNumberController.text.trim());
  }

  bool _isValidIFSC(String ifsc) {
    // IFSC code should be 11 characters: 4 letters + 0 + 6 alphanumeric
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return ifscRegex.hasMatch(ifsc.toUpperCase());
  }

  bool _isValidAccountNumber(String accountNumber) {
    // Remove spaces and check if it's numeric and between 9-18 digits
    final cleanedNumber = accountNumber.replaceAll(' ', '');
    return cleanedNumber.length >= 9 &&
        cleanedNumber.length <= 18 &&
        RegExp(r'^\d+$').hasMatch(cleanedNumber);
  }

  Future<void> _handleSubmit() async {
    // Validate all fields
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getValidationMessage()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final requestBody = {
        "bankDetails": {
          "accountHolderName": _accountHolderController.text.trim(),
          "bankName": _bankNameController.text.trim(),
          "accountNumber": _accountNumberController.text.trim().replaceAll(' ', ''),
          "ifscCode": _ifscCodeController.text.trim().toUpperCase(),
        }
      };

      // Call API to update astrologer profile with bank details
      final homeService = HomeService();
      final response = await homeService.updateAstrologerProfile(
        body: requestBody,
      );

      // If successful, show success dialog and navigate to home
      if (response['message'] == 'Profile updated') {
        // Show success dialog
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update bank details');
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bank details: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getValidationMessage() {
    if (_accountHolderController.text.trim().isEmpty) {
      return 'Please enter account holder name';
    }
    if (_bankNameController.text.trim().isEmpty) {
      return 'Please enter bank name';
    }
    if (_accountNumberController.text.trim().isEmpty) {
      return 'Please enter account number';
    }
    if (!_isValidAccountNumber(_accountNumberController.text.trim())) {
      return 'Please enter a valid account number (9-18 digits)';
    }
    if (_ifscCodeController.text.trim().isEmpty) {
      return 'Please enter IFSC code';
    }
    if (!_isValidIFSC(_ifscCodeController.text.trim())) {
      return 'Please enter a valid IFSC code (e.g., HDFC0001234)';
    }
    return 'Please fill in all bank details';
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bank Details Saved!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your bank details have been securely saved for processing payouts.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                    (route) => false,
              ); // Navigate to home and clear stack
            },
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A7C59),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A), size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Bank Verification',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4A7C59),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Details',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadBankDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7C59),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Bank Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4A7C59).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.account_balance,
                    size: 40,
                    color: Color(0xFF4A7C59),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Title and Subtitle
            Text(
              'Bank Verification',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'To process payouts',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 40),

            // Account Holder Name
            _buildInputField(
              label: 'Account Holder Name',
              controller: _accountHolderController,
              hintText: 'Enter account holder name',
            ),

            const SizedBox(height: 24),

            // Bank Name
            _buildInputField(
              label: 'Bank Name',
              controller: _bankNameController,
              hintText: 'Enter bank name',
            ),

            const SizedBox(height: 24),

            // Account Number
            _buildInputField(
              label: 'Account Number',
              controller: _accountNumberController,
              hintText: 'Enter account number',
              keyboardType: TextInputType.number,
              validator: _isValidAccountNumber,
              errorText: 'Invalid account number (9-18 digits)',
            ),

            const SizedBox(height: 24),

            // IFSC Code
            _buildInputField(
              label: 'IFSC Code',
              controller: _ifscCodeController,
              hintText: 'Enter IFSC code (e.g., HDFC0001234)',
              textCapitalization: TextCapitalization.characters,
              validator: _isValidIFSC,
              errorText: 'Invalid IFSC code format',
            ),

            const SizedBox(height: 16),

            // Security Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A7C59).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4A7C59).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF4A7C59),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your bank details are encrypted and stored securely',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF4A7C59),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: _canSubmit
                    ? const Color(0xFF4A7C59)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _canSubmit
                    ? [
                  BoxShadow(
                    color: const Color(0xFF4A7C59).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: _canSubmit && !_isSubmitting ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.transparent,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Submit',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.words,
    bool Function(String)? validator,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: controller.text.isNotEmpty &&
                  validator != null &&
                  !validator(controller.text)
                  ? Colors.red.shade300
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                textCapitalization: textCapitalization,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  setState(() {
                    // Trigger rebuild to update button state and validation
                  });
                },
              ),
              if (controller.text.isNotEmpty &&
                  validator != null &&
                  !validator(controller.text) &&
                  errorText != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorText,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }
}