import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pure White Page Background (#FFFFFF)
  static const Color pageBackground = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  // Primary Accent Colors (Vibrant Violet / Purple Gradient)
  static const Color primaryViolet = Color(0xFF7C3AED);
  static const Color indigoPrimary = Color(0xFF6366F1);
  static const Color purpleSecondary = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color purpleSubtle = Color(0xFFF5F3FF);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color coralDanger = Color(0xFFEF4444);
  static const Color pinkAccent = Color(0xFFEC4899);
  static const Color pinkTertiary = Color(0xFFEC4899);

  // Surface & Card Colors (Pure White & Layered Surfaces)
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color surfaceHighlight = Color(0xFFF1F5F9);
  
  // Borders & Dividers (Subtle, Clean)
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderPurple = Color(0x337C3AED);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // Dark Typography Colors (High Contrast on White)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Backward-compatibility aliases (Directing to Pure White & Clean Contrast)
  static const Color darkBackground = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFFFFFFFF);
  static const Color darkSurfaceContainer = Color(0xFFF8FAFC);
  static const Color darkSurfaceContainerHigh = Color(0xFFF1F5F9);
  static const Color darkSurfaceSubtle = Color(0xFFF8FAFC);
  static const Color darkSurfaceCard = Color(0xFFFFFFFF);
  static const Color darkBorder = Color(0xFFE2E8F0);
  static const Color darkBorderSubtle = Color(0xFFF1F5F9);
  static const Color darkOnSurface = Color(0xFF0F172A);
  static const Color darkOnSurfaceVariant = Color(0xFF64748B);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkDivider = Color(0xFFE2E8F0);

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFF8FAFC);
  static const Color lightSurfaceContainerHigh = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);

  static const Color primary = primaryViolet;
  static const Color primaryColor = primaryViolet;
  static const Color primaryContainer = Color(0xFFEDE9FE);
  static const Color onPrimaryContainer = Color(0xFF5B21B6);
  static const Color secondary = purpleSecondary;
  static const Color secondaryContainer = Color(0xFFF3E8FF);
  static const Color onSecondaryContainer = Color(0xFF6B21A8);
  static const Color tertiary = cyanAccent;
  static const Color tertiaryContainer = Color(0xFFE0F2FE);
  static const Color surface = cardWhite;
  static const Color surfaceContainer = surfaceSubtle;
  static const Color surfaceContainerHigh = surfaceHighlight;
  static const Color background = pageBackground;
  static const Color onSurface = textPrimary;
  static const Color onSurfaceVariant = textMuted;
  static const Color outline = borderLight;

  // Soft Card Shadows
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> subtleCardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Gradients (Vibrant Purple Branding)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleSubtleGradient = LinearGradient(
    colors: [Color(0xFFFAF5FF), Color(0xFFF5F3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroOverlayGradient = LinearGradient(
    colors: [
      Color(0xCC0F172A),
      Color(0x800F172A),
      Color(0x330F172A),
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme (Default Pure White Background)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: pageBackground,
      primaryColor: primaryViolet,
      canvasColor: cardWhite,
      colorScheme: const ColorScheme.light(
        surface: cardWhite,
        primary: primaryViolet,
        primaryContainer: Color(0xFFEDE9FE),
        onPrimaryContainer: Color(0xFF5B21B6),
        secondary: purpleSecondary,
        secondaryContainer: Color(0xFFF3E8FF),
        onSecondaryContainer: Color(0xFF6B21A8),
        tertiary: cyanAccent,
        error: coralDanger,
        onSurface: textPrimary,
        onSurfaceVariant: textMuted,
        outline: borderLight,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryViolet,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
      cardTheme: CardTheme(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pageBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerLight,
        thickness: 1,
      ),
    );
  }

  // Dark Theme (Aligned to Pure White #FFFFFF per User Requirement)
  static ThemeData get darkTheme => lightTheme;
}
