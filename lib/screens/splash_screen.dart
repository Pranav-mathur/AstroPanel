import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadToken();

    // Optional: delay to show splash for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1006),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [Color(0xFF2A1A0C), Color(0xFF1E1006)],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                // Top spacer - takes up specific portion of screen
                SizedBox(height: screenHeight * 0.5),

                // App Logo Asset - fixed size relative to screen
                Image.asset(
                  'assets/images/AstroIcon.png',
                  width: screenHeight * 0.2, // 20% of screen height
                  height: screenHeight * 0.2,
                ),

                // Fixed spacing between logo and loader
                SizedBox(height: screenHeight * 0.08), // 8% of screen height
                // Loading indicator - fixed size
                SizedBox(
                  width:
                  screenHeight *
                      0.045, // Approx 18 logical pixels relative to screen height
                  height: screenHeight * 0.045,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),

                // Bottom spacer - takes remaining space
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }

}