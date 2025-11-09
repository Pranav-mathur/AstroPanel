import 'package:astro_panel/providers/auth_provider.dart';
import 'package:astro_panel/providers/global_provider.dart';
import 'package:astro_panel/providers/home_provider.dart';
import 'package:astro_panel/providers/kyc_provider.dart';
import 'package:astro_panel/screens/bank_details_screen.dart';
import 'package:astro_panel/screens/home_screen.dart';
import 'package:astro_panel/screens/kyc_verification_screen.dart';
import 'package:astro_panel/screens/login_screen.dart';
import 'package:astro_panel/screens/otp_verification_screen.dart';
import 'package:astro_panel/screens/past_bookings_screen.dart';
import 'package:astro_panel/screens/profile_details_screen.dart';
import 'package:astro_panel/screens/services_screen.dart';
import 'package:astro_panel/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider(create: (_) => GlobalProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casa Darzi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OtpVerificationScreen(phoneNumber: ''),
        '/home': (context) => const HomeScreen(),
        '/kyc': (context) => const KycVerificationScreen(),
        '/profile-details': (context) => const ProfileDetailsScreen(),
        '/services': (context) => const ServicesScreen(),
        '/past-bookings': (context) => const PastBookingsScreen(),
        '/bank-details': (context) => const BankDetailsScreen(),
      },
    );
  }
}