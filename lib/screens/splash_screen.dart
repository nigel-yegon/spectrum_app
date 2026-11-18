// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spectrum/screens/pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 2.5 seconds, then navigate to the Dashboard
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const PinScreen(),
            transitionsBuilder: (_, animation, __, child) {
              // Smooth fade transition
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Deep green background matching the reference design
    const Color primaryGreen = Color(0xFF1E3A2F);

    return Scaffold(
      backgroundColor: primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─── Logo / Icon ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.apartment_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // ─── App Name ────────────────────────────────────────
            Text(
              'Spectrum',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // ─── Tagline / Context ───────────────────────────────
            Text(
              'Property Management, Elevated.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 64),

            // ─── Loading Indicator ───────────────────────────────
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFFA9D9B6), // Soft green from design
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}