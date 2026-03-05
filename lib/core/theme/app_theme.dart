import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
<<<<<<< HEAD
  static const background = Color(0xFF0B1118);
  static const surface = Color(0xFF121B24);
  static const surfaceAlt = Color(0xFF1A2633);
  static const primary = Color(0xFF12D6A0);
  static const secondary = Color(0xFF51C9FF);
  static const success = Color(0xFF29E19F);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9AB1C6);
  static const border = Color(0xFF244055);
  static const error = Color(0xFFFF6B6B);
}

class AppGradients {
  static const scaffold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF081018), Color(0xFF102434), Color(0xFF0A141D)],
  );

  static const button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, AppColors.secondary],
  );
=======
  // Dark theme
  static const background = Color(0xFF0F0F0F);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF242424);
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF9D97FF);
  static const success = Color(0xFF4CAF50);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9E9E9E);
  static const error = Color(0xFFEF5350);

  // Light theme
  static const lightBackground = Color(0xFFF7F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFEEEEF8);
  static const lightPrimary = Color(0xFF6C63FF);
  static const lightTextPrimary = Color(0xFF1A1A2E);
  static const lightTextSecondary = Color(0xFF7B7B9D);
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
<<<<<<< HEAD
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 22,
=======
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
<<<<<<< HEAD
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
=======
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
<<<<<<< HEAD
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.background,
=======
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
<<<<<<< HEAD
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(double.infinity, 56),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
=======
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
<<<<<<< HEAD
        thumbColor: AppColors.secondary,
        inactiveTrackColor: AppColors.surfaceAlt,
        overlayColor: Color(0x3312D6A0),
=======
        thumbColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceElevated,
        overlayColor: Color(0x226C63FF),
        trackHeight: 4,
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
<<<<<<< HEAD
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
=======
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.manrope(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.manrope(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
<<<<<<< HEAD
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
=======
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? AppColors.primary : Colors.grey,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.surfaceElevated,
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
<<<<<<< HEAD
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
=======
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
>>>>>>> fe6d353a2e22cfe0b7e5778b3154e47f427773b4
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        primary: AppColors.lightPrimary,
        error: AppColors.error,
        onBackground: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
        onPrimary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.lightTextSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.lightPrimary,
        thumbColor: AppColors.lightPrimary,
        inactiveTrackColor: AppColors.lightSurfaceElevated,
        overlayColor: AppColors.lightPrimary.withOpacity(0.15),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.lightPrimary
              : Colors.grey.shade400,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.lightPrimary.withOpacity(0.4)
              : Colors.grey.shade200,
        ),
      ),
    );
  }
}
