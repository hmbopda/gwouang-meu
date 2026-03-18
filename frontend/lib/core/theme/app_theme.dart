import 'package:flutter/material.dart';

/// Palette couleurs GWANG MEU
abstract class AppColors {
  static const primary = Color(0xFFC8A020); // Or GWANG MEU
  static const primaryLight = Color(0xFFE8C040);
  static const primaryDark = Color(0xFF9A7810);

  static const background = Color(0xFF0D0D0D); // Fond sombre
  static const surface = Color(0xFF1A1A1A);    // Cartes
  static const surfaceAlt = Color(0xFF242424);  // Surfaces secondaires
  static const border = Color(0xFF333333);

  static const textPrimary = Color(0xFFF5F0E8);
  static const textSecondary = Color(0xFF999999);
  static const textHint = Color(0xFF666666);

  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE84C0A);
  static const warning = Color(0xFFF5A623);
  static const info = Color(0xFF2196F3);
}

/// Typographie GWANG MEU
abstract class AppTextStyles {
  static const _base = TextStyle(color: AppColors.textPrimary);

  static final displayLarge = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static final displayMedium = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700);
  static final headlineLarge = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w600);
  static final headlineMedium = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  static final titleLarge = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static final titleMedium = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500);
  static final bodyLarge = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400);
  static final bodyMedium = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400);
  static final bodySmall = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static final labelLarge = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5);
}

/// Palette du mode clair (inversé du sombre, même or primaire)
abstract class AppColorsLight {
  static const background = Color(0xFFFAFAF8);
  static const surface = Color(0xFFF0EBE0);
  static const surfaceAlt = Color(0xFFE8E2D8);
  static const border = Color(0xFFD8D0C0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textHint = Color(0xFF999999);
}

class AppTheme {
  // ── Thème sombre (avec couleur d'accent dynamique) ─────────────────────

  static ThemeData dark({
    Color? accent,
    Color? accentLight,
  }) {
    final primary = accent ?? AppColors.primary;
    final secondary = accentLight ?? AppColors.primaryLight;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: primary,

      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.black,
        secondary: secondary,
        onSecondary: Colors.black,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        outline: AppColors.border,
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        hintStyle: const TextStyle(color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Thème AMOLED (fond pur noir) ──────────────────────────────────────────

  static ThemeData amoled({Color? accent, Color? accentLight}) {
    final primary = accent ?? AppColors.primary;
    final secondary = accentLight ?? AppColors.primaryLight;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: primary,

      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.black,
        secondary: secondary,
        onSecondary: Colors.black,
        surface: const Color(0xFF0A0A0A),
        onSurface: Colors.white,
        error: AppColors.error,
        outline: const Color(0xFF222222),
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: Colors.white),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: Colors.white),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF888888)),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: Colors.white),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF0A0A0A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF222222), width: 0.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111111),
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF222222)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF222222)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFF666666),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(color: Color(0xFF222222), thickness: 0.5),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF111111),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Thème Contraste élevé ───────────────────────────────────────────────

  static ThemeData highContrast({Color? accent, Color? accentLight}) {
    final primary = accent ?? AppColors.primary;
    final secondary = accentLight ?? AppColors.primaryLight;
    const bg = Color(0xFF050505);
    const surface = Color(0xFF111111);
    const border = Color(0xFFAAAAAA);
    const textColor = Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,

      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.black,
        secondary: secondary,
        onSecondary: Colors.black,
        surface: surface,
        onSurface: textColor,
        error: const Color(0xFFFF4444),
        outline: border,
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: textColor, fontSize: 34, fontWeight: FontWeight.w800),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: textColor, fontSize: 28, fontWeight: FontWeight.w800),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: textColor, fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: textColor, fontSize: 20, fontWeight: FontWeight.w700),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textColor, fontSize: 17, fontWeight: FontWeight.w500),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFCCCCCC), fontSize: 13, fontWeight: FontWeight.w500),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: textColor, fontSize: 15, fontWeight: FontWeight.w700),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w700),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: primary, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 54),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFFAAAAAA),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textColor, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Thème clair ───────────────────────────────────────────────────────────

  static ThemeData light({Color? accent, Color? accentLight}) {
    final primary = accent ?? AppColors.primary;
    final secondary = accentLight ?? AppColors.primaryDark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorsLight.background,
      primaryColor: primary,

      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.black,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: AppColorsLight.surface,
        onSurface: AppColorsLight.textPrimary,
        error: AppColors.error,
        outline: AppColorsLight.border,
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColorsLight.textPrimary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColorsLight.textPrimary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColorsLight.textPrimary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColorsLight.textPrimary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColorsLight.textPrimary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColorsLight.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColorsLight.textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColorsLight.textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColorsLight.textSecondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColorsLight.textPrimary),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsLight.background,
        foregroundColor: AppColorsLight.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColorsLight.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColorsLight.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColorsLight.border, width: 0.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.surfaceAlt,
        hintStyle: const TextStyle(color: AppColorsLight.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.surface,
        selectedItemColor: primary,
        unselectedItemColor: AppColorsLight.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColorsLight.border,
        thickness: 0.5,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsLight.surfaceAlt,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColorsLight.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
