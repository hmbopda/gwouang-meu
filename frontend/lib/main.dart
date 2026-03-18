import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/theme/theme_notifier.dart';

void main() async {
  final mainStart = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('[Perf] main() start → binding: ${DateTime.now().difference(mainStart).inMilliseconds}ms');
  }

  // ── Charger SharedPreferences avant l'app (lecture rapide, sync-like) ──
  final prefs = await SharedPreferences.getInstance();

  // ── Filtre mouse_tracker en debug (bug connu Flutter Web) ──
  if (kDebugMode) {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('mouse_tracker')) return;
      originalOnError?.call(details);
    };
  }

  // ── Premier frame IMMÉDIAT — pas d'await bloquant ──
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: BootstrapApp(mainStartTime: mainStart),
    ),
  );

  if (kDebugMode) {
    debugPrint('[Perf] runApp() called: ${DateTime.now().difference(mainStart).inMilliseconds}ms');
  }
}
