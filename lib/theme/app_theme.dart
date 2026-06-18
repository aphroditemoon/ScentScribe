
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {

  static const Color obsidian = Color(0xFF0A0A0F);
  static const Color charcoalDark = Color(0xFF111118);
  static const Color charcoal = Color(0xFF1A1A26);
  static const Color charcoalLight = Color(0xFF252535);
  static const Color surface = Color(0xFF1E1E2E);
  static const Color surfaceVariant = Color(0xFF2A2A3E);


  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C547);
  static const Color goldDim = Color(0xFF8B7320);
  static const Color amethyst = Color(0xFF9B59B6);
  static const Color amethystLight = Color(0xFFBB77D6);
  static const Color roseGold = Color(0xFFB76E79);
  static const Color peach = Color(0xFFFFB6A3);
  static const Color blush = Color(0xFFFFD6CC);


  static const Color success = Color(0xFF4ECDC4);
  static const Color warning = Color(0xFFFFD166);
  static const Color error = Color(0xFFEF476F);
  static const Color info = Color(0xFF118AB2);


  static const Color textPrimary = Color(0xFFF5F5F0);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6B6B7E);
  static const Color textInverse = Color(0xFF0A0A0F);


  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFB8860B), Color(0xFFD4AF37)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient amethystGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0F), Color(0xFF1A1A26)],
  );

  static const RadialGradient glowGold = RadialGradient(
    colors: [Color(0x40D4AF37), Color(0x00D4AF37)],
  );

  static const RadialGradient glowAmethyst = RadialGradient(
    colors: [Color(0x409B59B6), Color(0x009B59B6)],
  );


  static const Color topNote = Color(0xFFFFD166);
  static const Color heartNote = Color(0xFFEF476F);
  static const Color baseNote = Color(0xFF9B59B6);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.obsidian,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.amethyst,
        tertiary: AppColors.roseGold,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.obsidian,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
      chipTheme: _buildChipTheme(),
      dividerTheme: const DividerThemeData(
        color: AppColors.charcoalLight,
        thickness: 0.5,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(

      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 57, fontWeight: FontWeight.w300,
        color: AppColors.textPrimary, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.cormorantGaramond(
        fontSize: 45, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, letterSpacing: -0.25,
      ),
      displaySmall: GoogleFonts.cormorantGaramond(
        fontSize: 36, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),

      headlineLarge: GoogleFonts.cormorantGaramond(
        fontSize: 32, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.3,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 28, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        fontSize: 24, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),

      titleLarge: GoogleFonts.dmSans(
        fontSize: 22, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.1,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary, letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary, letterSpacing: 0.1,
      ),

      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, letterSpacing: 0.15,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textMuted, letterSpacing: 0.4,
      ),

      labelLarge: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary, letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w500,
        color: AppColors.textMuted, letterSpacing: 1.5,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.obsidian,
      ),
      titleTextStyle: GoogleFonts.cormorantGaramond(
        fontSize: 20, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary, letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.charcoalLight, width: 0.5),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.obsidian,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: const BorderSide(color: AppColors.gold, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.charcoalLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.charcoalLight, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      labelStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
      hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme() {
    return const BottomNavigationBarThemeData(
      backgroundColor: AppColors.charcoalDark,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }

  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.gold.withOpacity(0.2),
      side: const BorderSide(color: AppColors.charcoalLight),
      labelStyle: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
