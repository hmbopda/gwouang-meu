import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/villages/village_detail_screen.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/features/villages/villages_screen.dart';
import 'package:gwangmeu/shared/models/village_model.dart';

/// Pont origine → communauté : si l'utilisateur n'appartient à aucun village mais
/// a une origine référentielle, on matérialise + rejoint son village d'origine
/// (chefferie → communauté). Auto-dispose : rejoué à chaque réouverture de l'onglet.
final _originBridgeProvider = FutureProvider.autoDispose<VillageModel?>((ref) {
  return ref.read(myVillagesNotifierProvider.notifier).joinOriginVillage();
});

/// Destination de l'onglet « Villages ».
///
/// Ouvre le NOUVEL écran village (patrimoine) sur le premier village de
/// l'utilisateur. S'il n'appartient à aucun village, on tente d'abord d'ouvrir
/// son **village d'origine** (matérialisé depuis le référentiel) ; à défaut
/// d'origine, on montre l'écran d'exploration pour en découvrir/rejoindre.
class VillagesHubScreen extends ConsumerWidget {
  const VillagesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final myVillages = ref.watch(myVillagesNotifierProvider);

    Widget loader() => Scaffold(
          backgroundColor: t.ink,
          body: Center(
            child: CircularProgressIndicator(color: t.goldText, strokeWidth: 2),
          ),
        );

    return myVillages.when(
      loading: () => loader(),
      // Erreur réseau (backend en réveil) → exploration ; le retry du client
      // API couvre le cold start.
      error: (_, __) => const VillagesScreen(),
      data: (villages) {
        if (villages.isNotEmpty) {
          // Village par défaut = le premier ; le panneau gauche (desktop) et le
          // sélecteur (mobile) permettent de switcher.
          return VillageDetailScreen(villageId: villages.first.id);
        }
        // Aucun village membre → tenter d'ouvrir le village d'origine (auto).
        final bridge = ref.watch(_originBridgeProvider);
        return bridge.when(
          loading: () => loader(),
          error: (_, __) => const VillagesScreen(),
          data: (village) => village != null
              ? VillageDetailScreen(villageId: village.id)
              : const VillagesScreen(),
        );
      },
    );
  }
}
