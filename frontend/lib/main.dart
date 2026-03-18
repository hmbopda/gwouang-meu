import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  final mainStart = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('[Perf] main() start → binding: ${DateTime.now().difference(mainStart).inMilliseconds}ms');
  }

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
      child: BootstrapApp(mainStartTime: mainStart),
    ),
  );

  if (kDebugMode) {
    debugPrint('[Perf] runApp() called: ${DateTime.now().difference(mainStart).inMilliseconds}ms');
  }
}
