import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/villages/village_detail_screen.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/features/villages/villages_screen.dart';

/// Destination de l'onglet « Villages ».
///
/// Ouvre directement le NOUVEL écran village (village_detail_screen, avec le
/// panneau « MES VILLAGES » à gauche pour changer de village) sur le premier
/// village de l'utilisateur. Si l'utilisateur n'appartient à aucun village,
/// on montre l'écran d'exploration (VillagesScreen) pour en découvrir/rejoindre.
class VillagesHubScreen extends ConsumerWidget {
  const VillagesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final myVillages = ref.watch(myVillagesNotifierProvider);

    return myVillages.when(
      loading: () => Scaffold(
        backgroundColor: t.ink,
        body: Center(
          child: CircularProgressIndicator(color: t.goldText, strokeWidth: 2),
        ),
      ),
      // En cas d'erreur réseau (backend en réveil), on retombe sur l'exploration
      // plutôt que sur un écran vide ; le retry du client API couvre le cold start.
      error: (_, __) => const VillagesScreen(),
      data: (villages) {
        if (villages.isEmpty) {
          // Aucun village → écran d'exploration pour en rejoindre un.
          return const VillagesScreen();
        }
        // Village par défaut = le premier ; le panneau gauche permet de switcher.
        return VillageDetailScreen(villageId: villages.first.id);
      },
    );
  }
}
