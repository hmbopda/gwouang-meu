import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';

/// Écran de retour des liens d'authentification par email — style « Tissage ».
///
/// Atteint par le deep link `/auth-callback` (custom scheme mobile, ou URL de
/// l'app sur web). Le SDK supabase-flutter a déjà consommé le fragment/les
/// paramètres de l'URL au démarrage : ici on se contente d'afficher une
/// confirmation « Email confirmé » puis de rediriger.
///
/// Le cas `type=recovery` (mot de passe oublié) est traité en amont par le
/// router (redirection vers /reset-password), donc cet écran ne gère que la
/// confirmation d'inscription.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    // Laisse une courte confirmation visible, puis route selon la session.
    _redirectTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      final hasSession =
          Supabase.instance.client.auth.currentSession != null;
      context.go(hasSession ? Routes.feed : Routes.auth);
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: GwTokens.sageBg,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: GwTokens.sageLine, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Symbols.mark_email_read,
                            size: 34, color: t.sageText),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'BIENVENUE',
                        style: GwType.mono(
                            fontSize: 10,
                            color: t.goldText,
                            letterSpacing: 2.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email confirmé',
                        textAlign: TextAlign.center,
                        style: GwType.display(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: t.stone),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Votre compte est vérifié. Nous vous emmenons dans '
                        'votre communauté…',
                        textAlign: TextAlign.center,
                        style: GwType.ui(
                            fontSize: 14.5, color: t.stoneMid, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GwTokens.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
