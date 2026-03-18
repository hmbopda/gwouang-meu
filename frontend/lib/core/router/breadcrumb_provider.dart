import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entrée du fil d'Ariane — label affiché + route pour navigation.
class BreadcrumbEntry {
  const BreadcrumbEntry({required this.label, required this.route});
  final String label;
  final String route;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BreadcrumbEntry && other.route == route;

  @override
  int get hashCode => route.hashCode;
}

/// Provider global qui gère la pile de breadcrumbs.
///
/// Usage :
///   - `ref.read(breadcrumbProvider.notifier).push(...)` avant chaque navigation
///   - `ref.read(breadcrumbProvider.notifier).popTo(route)` pour naviguer en arrière
///   - `ref.read(breadcrumbProvider.notifier).reset(...)` quand on arrive sur un onglet principal
class BreadcrumbNotifier extends StateNotifier<List<BreadcrumbEntry>> {
  BreadcrumbNotifier() : super(const []);

  /// Ajoute une étape au fil d'Ariane.
  /// Si la route existe déjà dans la pile, tronque jusqu'à cette route (évite les doublons).
  void push(BreadcrumbEntry entry) {
    final existingIndex = state.indexWhere((e) => e.route == entry.route);
    if (existingIndex >= 0) {
      // Déjà dans la pile → tronquer jusqu'à cette position
      state = state.sublist(0, existingIndex + 1);
    } else {
      state = [...state, entry];
    }
  }

  /// Tronque la pile jusqu'à la route donnée (incluse).
  void popTo(String route) {
    final index = state.indexWhere((e) => e.route == route);
    if (index >= 0) {
      state = state.sublist(0, index + 1);
    }
  }

  /// Reset complet avec une seule entrée racine (onglet principal).
  void reset(BreadcrumbEntry root) {
    state = [root];
  }

  /// Vide la pile.
  void clear() {
    state = const [];
  }
}

final breadcrumbProvider =
    StateNotifierProvider<BreadcrumbNotifier, List<BreadcrumbEntry>>(
  (ref) => BreadcrumbNotifier(),
);
