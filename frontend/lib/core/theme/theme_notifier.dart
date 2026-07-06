import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const _kThemeModeKey = 'gw_display_mode';
const _kAccentColorKey = 'gw_accent_color';

// ── Provider SharedPreferences (singleton) ────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override this provider in ProviderScope');
});

// ── Provider mode d'affichage ─────────────────────────────────

final displayModeProvider =
    StateNotifierProvider<DisplayModeNotifier, DisplayMode>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return DisplayModeNotifier(prefs);
  },
);

class DisplayModeNotifier extends StateNotifier<DisplayMode> {
  DisplayModeNotifier(this._prefs) : super(_loadMode(_prefs));

  final SharedPreferences _prefs;

  static DisplayMode _loadMode(SharedPreferences prefs) {
    final saved = prefs.getString(_kThemeModeKey);
    if (saved == null) return DisplayMode.dark; // dark par défaut
    return DisplayMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => DisplayMode.dark,
    );
  }

  void setMode(DisplayMode mode) {
    state = mode;
    _prefs.setString(_kThemeModeKey, mode.name);
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
    color: Color(0xFFC9A84C),
    light: Color(0xFFE8C96A),
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

// ── Provider couleur accent ───────────────────────────────────

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, AccentColor>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AccentColorNotifier(prefs);
  },
);

class AccentColorNotifier extends StateNotifier<AccentColor> {
  AccentColorNotifier(this._prefs) : super(_loadAccent(_prefs));

  final SharedPreferences _prefs;

  static AccentColor _loadAccent(SharedPreferences prefs) {
    final saved = prefs.getString(_kAccentColorKey);
    if (saved == null) return kAccentColors[0]; // Or par défaut
    return kAccentColors.firstWhere(
      (a) => a.name == saved,
      orElse: () => kAccentColors[0],
    );
  }

  void setAccent(AccentColor accent) {
    state = accent;
    _prefs.setString(_kAccentColorKey, accent.name);
  }
}

// ── Rétrocompatibilité ──
final themeModeProvider = Provider<ThemeMode>((_) => ThemeMode.dark);
