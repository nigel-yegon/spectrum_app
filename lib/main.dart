import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'providers/app_state.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Database setup for different platforms
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const SpectrumApp());
}

class SpectrumApp extends StatelessWidget {
  const SpectrumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..loadAll(),
      child: MaterialApp(
        title: 'Spectrum',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const SplashScreen(), // <--- Routes to Splash first
      ),
    );
  }

  ThemeData _buildTheme() {
    // The deep green from the reference image
    const primaryGreen = Color(0xFF1E3A2F);
    const bgCream = Color(0xFFF9F9F6);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        surface: bgCream,
      ),
      // Use Inter for a clean, fintech look
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgCream,
        foregroundColor: primaryGreen,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
        iconTheme: const IconThemeData(color: primaryGreen),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryGreen.withOpacity(0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen);
          }
          return const IconThemeData(color: Colors.grey);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: primaryGreen);
          }
          return GoogleFonts.inter(fontSize: 12, color: Colors.grey);
        }),
      ),
    );
  }
}