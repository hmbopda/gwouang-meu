import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gwangmeu/core/cache/cache_service.dart';
import 'package:gwangmeu/core/connectivity/offline_banner.dart';
import 'package:gwangmeu/core/notifications/notification_service.dart';
import 'package:gwangmeu/core/router/app_router.dart';
import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/core/theme/theme_notifier.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/firebase_options.dart';

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

    // ── Hive, Firebase et Supabase en PARALLÈLE ──
    final tParallel = DateTime.now();
    final futures = <Future>[
      CacheService.init(),
      Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      ),
    ];
    // Firebase non supporté sur Web (pas de google-services web configuré)
    if (!kIsWeb) {
      futures.add(Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform));
    }
    await Future.wait(futures);
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
    if (kDebugMode) {
      debugPrint('[Perf] Hive+Firebase+Supabase (parallèle): ${DateTime.now().difference(tParallel).inMilliseconds}ms');
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF080709),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GWANG MEU',
                style: TextStyle(
                  color: Color(0xFFD4A843),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
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

class GwangMeuApp extends ConsumerStatefulWidget {
  const GwangMeuApp({super.key});

  @override
  ConsumerState<GwangMeuApp> createState() => _GwangMeuAppState();
}

class _GwangMeuAppState extends ConsumerState<GwangMeuApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Notifications FCM uniquement sur mobile (non supporté sur web)
      if (!kIsWeb) {
        ref.read(notificationServiceProvider).init();
      }
      // Pré-charger la fiche personne généalogie en arrière-plan dès le
      // démarrage. GenealogyNotifier est keepAlive : l'état préchargé est
      // conservé et réutilisé quand l'utilisateur ouvre l'écran généalogie.
      ref.read(genealogyNotifierProvider.future).ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
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
      builder: (context, child) => OfflineBanner(child: child ?? const SizedBox.shrink()),
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
