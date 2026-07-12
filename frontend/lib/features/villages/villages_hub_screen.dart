import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/villages/village_detail_screen.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/features/villages/villages_screen.dart';
import 'package:gwangmeu/shared/models/village_model.dart';

/// Pont origine → communauté. Au premier affichage de l'onglet Villages, on
/// matérialise + rejoint le village d'ORIGINE de l'utilisateur (chefferie du
/// référentiel → communauté), même s'il suit déjà d'autres villages. Idempotent,
/// exécuté une seule fois par session (non-autoDispose → pas de boucle avec
/// l'invalidation de « mes villages »). Renvoie `null` si aucune origine.
final _originBridgeProvider = FutureProvider<VillageModel?>((ref) {
  return ref.read(myVillagesNotifierProvider.notifier).joinOriginVillage();
});

/// Destination de l'onglet « Villages ».
///
/// Ouvre en priorité le **village d'origine** de l'utilisateur (matérialisé
/// depuis le référentiel) ; à défaut, son premier village ; à défaut d'origine
/// et de village, l'écran d'exploration. Le panneau gauche (desktop) et le
/// sélecteur (mobile) permettent de basculer entre tous ses villages.
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
    Widget open(String id) => VillageDetailScreen(villageId: id);

    return myVillages.when(
      loading: () => loader(),
      // Erreur réseau (backend en réveil) → exploration ; le retry du client
      // API couvre le cold start.
      error: (_, __) => const VillagesScreen(),
      data: (villages) {
        final bridge = ref.watch(_originBridgeProvider);
        return bridge.when(
          // Pendant la résolution du village d'origine, on affiche déjà un
          // village existant s'il y en a (pas d'écran blanc).
          loading: () =>
              villages.isNotEmpty ? open(villages.first.id) : loader(),
          error: (_, __) =>
              villages.isNotEmpty ? open(villages.first.id) : const VillagesScreen(),
          data: (origin) {
            if (origin != null) return open(origin.id); // village d'origine
            if (villages.isNotEmpty) return open(villages.first.id);
            return const VillagesScreen(); // ni origine ni village → exploration
          },
        );
      },
    );
  }
}
