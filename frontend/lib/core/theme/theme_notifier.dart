import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Mode d'affichage ──────────────────────────────────────────

enum DisplayMode {
  dark('Sombre', Icons.dark_mode, 'Fond gris foncé, confortable'),
  light('Clair', Icons.light_mode, 'Fond blanc, lecture de jour'),
  amoled('AMOLED', Icons.brightness_2, 'Fond pur noir, économie batterie'),
  highContrast('Contraste', Icons.contrast, 'Lisibilité maximale');

  const DisplayMode(this.label, this.icon, this.description);

  final String label;
  final IconData icon;
  final String description;
}

final displayModeProvider =
    StateNotifierProvider<DisplayModeNotifier, DisplayMode>(
  (ref) => DisplayModeNotifier(),
);

class DisplayModeNotifier extends StateNotifier<DisplayMode> {
  DisplayModeNotifier() : super(DisplayMode.light);

  void setMode(DisplayMode mode) {
    state = mode;
  }
}

// ── Couleurs d'accent ─────────────────────────────────────────

class AccentColor {
  const AccentColor({
    required this.name,
    required this.color,
    required this.light,
    required this.dark,
  });

  final String name;
  final Color color;
  final Color light;
  final Color dark;
}

const kAccentColors = [
  AccentColor(
    name: 'Or',
    color: Color(0xFFC8A020),
    light: Color(0xFFE8C040),
    dark: Color(0xFF9A7810),
  ),
  AccentColor(
    name: 'Ambre',
    color: Color(0xFFE8973A),
    light: Color(0xFFF5B060),
    dark: Color(0xFFB87020),
  ),
  AccentColor(
    name: 'Émeraude',
    color: Color(0xFF2EAA6E),
    light: Color(0xFF50CC8E),
    dark: Color(0xFF1A7A4A),
  ),
  AccentColor(
    name: 'Saphir',
    color: Color(0xFF3A7BD5),
    light: Color(0xFF6AA0F0),
    dark: Color(0xFF2558A0),
  ),
  AccentColor(
    name: 'Rubis',
    color: Color(0xFFD44040),
    light: Color(0xFFE86060),
    dark: Color(0xFFA02828),
  ),
  AccentColor(
    name: 'Violet',
    color: Color(0xFF8B5CF6),
    light: Color(0xFFA78BFA),
    dark: Color(0xFF6D40D0),
  ),
  AccentColor(
    name: 'Rose',
    color: Color(0xFFE84C8A),
    light: Color(0xFFF070A8),
    dark: Color(0xFFB03068),
  ),
  AccentColor(
    name: 'Cyan',
    color: Color(0xFF06B6D4),
    light: Color(0xFF30D0E8),
    dark: Color(0xFF0890A8),
  ),
];

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, AccentColor>(
  (ref) => AccentColorNotifier(),
);

class AccentColorNotifier extends StateNotifier<AccentColor> {
  AccentColorNotifier() : super(kAccentColors[0]); // Or par défaut

  void setAccent(AccentColor accent) {
    state = accent;
  }
}

// ── Rétrocompatibilité ──
final themeModeProvider = Provider<ThemeMode>((_) => ThemeMode.light);
