import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';

/// Thèmes GWANG MEU « Tissage » — construits sur [GwTokens].
///
/// Typographies : Fraunces (titres), Syne (interface), JetBrains Mono (méta).
/// Rayons : cartes 18 px, boutons/inputs 14 px, pilules 99 px.
/// Accessibilité : corps ≥ 14 px, cibles ≥ 44 px, contraste AA.
class AppTheme {
  static TextTheme _textTheme(GwTokens t) {
    return TextTheme(
      // Fraunces — titres & récits
      displayLarge: GwType.display(fontSize: 32, color: t.stone),
      displayMedium: GwType.display(fontSize: 26, color: t.stone),
      headlineLarge: GwType.display(fontSize: 22, color: t.stone),
      headlineMedium: GwType.display(
          fontSize: 18, fontWeight: FontWeight.w600, color: t.stone),
      // Syne — interface
      titleLarge: GwType.ui(
          fontSize: 16, fontWeight: FontWeight.w600, color: t.stone),
      titleMedium: GwType.ui(
          fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
      bodyLarge: GwType.ui(fontSize: 15, color: t.stone),
      bodyMedium: GwType.ui(fontSize: 14, color: t.stone),
      bodySmall: GwType.ui(fontSize: 12, color: t.stoneMid),
      labelLarge: GwType.ui(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: t.stone,
          letterSpacing: 0.3),
      // JetBrains Mono — méta & badges
      labelSmall: GwType.mono(fontSize: 11, color: t.stoneDim),
    );
  }

  static ThemeData _base(
    GwTokens t, {
    required Color primary,
    required Color secondary,
    Color? scaffold,
    Color? card,
    Color? lift,
    Color? outline,
    double borderWidth = 1,
  }) {
    final bg = scaffold ?? t.ink;
    final cardColor = card ?? t.inkCard;
    final liftColor = lift ?? t.inkLift;
    final lineColor = outline ?? t.line;
    final isDark = t.brightness == Brightness.dark;
    final onPrimary = isDark ? const Color(0xFF0C0B0F) : Colors.white;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: primary,
            onPrimary: onPrimary,
            secondary: secondary,
            onSecondary: onPrimary,
            surface: cardColor,
            onSurface: t.stone,
            error: GwTokens.ember,
            outline: lineColor,
          )
        : ColorScheme.light(
            primary: primary,
            onPrimary: onPrimary,
            secondary: secondary,
            onSecondary: onPrimary,
            surface: cardColor,
            onSurface: t.stone,
            error: t.emberText,
            outline: lineColor,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: colorScheme,
      textTheme: _textTheme(t),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: t.stone,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: GwType.display(fontSize: 22, color: t.stone),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rCard),
          side: BorderSide(color: lineColor, width: borderWidth),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: liftColor,
        hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: lineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: lineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: GwType.ui(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.goldText,
          side: BorderSide(color: t.goldLine, width: 1.5),
          textStyle: GwType.ui(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
          ),
          minimumSize: const Size(0, GwTokens.tapTarget),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.goldText,
          textStyle: GwType.ui(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size(0, GwTokens.tapTarget),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: t.goldText,
        unselectedItemColor: t.stoneMid,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(color: lineColor, thickness: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: liftColor,
        contentTextStyle: GwType.ui(fontSize: 14, color: t.stone),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      iconTheme: IconThemeData(color: t.stoneMid, size: 22),
    );
  }

  // ── Thème sombre (ink) ────────────────────────────────────────
  static ThemeData dark({Color? accent, Color? accentLight}) {
    return _base(
      GwTokens.dark,
      primary: accent ?? GwTokens.gold,
      secondary: accentLight ?? GwTokens.goldLight,
    );
  }

  // ── Thème clair (paper) ───────────────────────────────────────
  static ThemeData light({Color? accent, Color? accentLight}) {
    return _base(
      GwTokens.light,
      primary: accent ?? GwTokens.gold,
      secondary: accentLight ?? GwTokens.goldDeep,
    );
  }

  // ── Thème AMOLED (fond pur noir, tokens ink) ─────────────────
  static ThemeData amoled({Color? accent, Color? accentLight}) {
    return _base(
      GwTokens.dark,
      primary: accent ?? GwTokens.gold,
      secondary: accentLight ?? GwTokens.goldLight,
      scaffold: Colors.black,
      card: const Color(0xFF0A0A0C),
      lift: const Color(0xFF141418),
    );
  }

  // ── Thème contraste élevé ─────────────────────────────────────
  static ThemeData highContrast({Color? accent, Color? accentLight}) {
    final theme = _base(
      GwTokens.dark,
      primary: accent ?? GwTokens.goldLight,
      secondary: accentLight ?? GwTokens.gold,
      scaffold: const Color(0xFF050505),
      card: const Color(0xFF111114),
      lift: const Color(0xFF1A1A20),
      outline: const Color(0xFFAAAAAA),
      borderWidth: 1.5,
    );
    // Tailles légèrement augmentées pour la lisibilité maximale.
    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyLarge: theme.textTheme.bodyLarge
            ?.copyWith(fontSize: 17, fontWeight: FontWeight.w500),
        bodyMedium: theme.textTheme.bodyMedium
            ?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
        bodySmall: theme.textTheme.bodySmall
            ?.copyWith(fontSize: 13, color: const Color(0xFFCCCCCC)),
      ),
    );
  }
}

/// Toast « Tissage » — pilule sage flottante (confirmations, succès IA).
void showGwToast(BuildContext context, String message,
    {Duration duration = const Duration(milliseconds: 3200)}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.syne(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: GwTokens.sage,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
      margin: const EdgeInsets.only(bottom: 24, left: 40, right: 40),
    ),
  );
}
