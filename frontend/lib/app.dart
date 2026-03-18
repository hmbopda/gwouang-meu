import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BootstrapApp — s'affiche INSTANTANÉMENT, init Supabase en arrière-plan
// ─────────────────────────────────────────────────────────────────────────────

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key, required this.mainStartTime});
  final DateTime mainStartTime;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('[Perf] BootstrapApp.initState: ${DateTime.now().difference(widget.mainStartTime).inMilliseconds}ms');
    }
    _initFuture = _initServices();
  }

  Future<void> _initServices() async {
    final t0 = DateTime.now();

    // ── dotenv ──
    await dotenv.load();
    if (kDebugMode) {
      debugPrint('[Perf] dotenv.load(): ${DateTime.now().difference(t0).inMilliseconds}ms');
    }

    // ── Supabase ──
    final t1 = DateTime.now();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    if (kDebugMode) {
      debugPrint('[Perf] Supabase.initialize(): ${DateTime.now().difference(t1).inMilliseconds}ms');
      debugPrint('[Perf] Total init: ${DateTime.now().difference(widget.mainStartTime).inMilliseconds}ms');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('[Perf] BootstrapApp.build: ${DateTime.now().difference(widget.mainStartTime).inMilliseconds}ms');
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        // ── Erreur fatale d'init ──
        if (snapshot.hasError) {
          if (kDebugMode) {
            debugPrint('[Perf] Init ERROR: ${snapshot.error}');
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF080709),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Erreur d\'initialisation.\nVeuillez relancer l\'application.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // ── Init en cours → splash instantané ──
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }

        if (kDebugMode) {
          debugPrint('[Perf] → GwangMeuApp rendered: ${DateTime.now().difference(widget.mainStartTime).inMilliseconds}ms');
        }

        // ── Prêt → app réelle ──
        return const GwangMeuApp();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SplashScreen — écran d'attente ultra-léger, même fond que le splash natif
// ─────────────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF080709),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GWANG MEU',
                style: TextStyle(
                  color: Color(0xFFD4A843),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0x99D4A843),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GwangMeuApp — app principale (chargée APRÈS init Supabase)
// ─────────────────────────────────────────────────────────────────────────────

class GwangMeuApp extends ConsumerWidget {
  const GwangMeuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final accent = ref.watch(accentColorProvider);
    final displayMode = ref.watch(displayModeProvider);

    final theme = _buildTheme(displayMode, accent);
    final isLight = displayMode == DisplayMode.light;

    return MaterialApp.router(
      title: 'GWANG MEU',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: isLight ? null : theme,
      themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      locale: const Locale('fr'),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme(DisplayMode mode, AccentColor accent) {
    switch (mode) {
      case DisplayMode.dark:
        return AppTheme.dark(accent: accent.color, accentLight: accent.light);
      case DisplayMode.light:
        return AppTheme.light(accent: accent.color, accentLight: accent.light);
      case DisplayMode.amoled:
        return AppTheme.amoled(accent: accent.color, accentLight: accent.light);
      case DisplayMode.highContrast:
        return AppTheme.highContrast(accent: accent.color, accentLight: accent.light);
    }
  }
}
