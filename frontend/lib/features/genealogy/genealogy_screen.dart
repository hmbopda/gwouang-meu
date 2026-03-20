import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/features/genealogy/state/tree_tokens.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/add_person_dialog.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/add_union_dialog.dart';
import 'package:gwangmeu/features/genealogy/widgets/left_panel/genealogy_left_panel.dart';
import 'package:gwangmeu/features/genealogy/widgets/right_panel/genealogy_right_panel.dart';
import 'package:gwangmeu/features/genealogy/widgets/tree_canvas/tree_canvas.dart';

class GenealogyScreen extends ConsumerWidget {
  const GenealogyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final myPersonAsync = ref.watch(genealogyNotifierProvider);
    final desktop = isDesktopLayout(context);

    final body = myPersonAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: accent),
      ),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(genealogyNotifierProvider),
      ),
      data: (myPerson) => _GenealogyBody(personId: myPerson.id),
    );

    if (desktop) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mon Arbre Genealogique',
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }
}

// ── Body principal — layout 3 colonnes ─────────────────────

class _GenealogyBody extends ConsumerWidget {
  const _GenealogyBody({required this.personId});
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final treeAsync = ref.watch(familyTreeProvider(personId));
    final desktop = isDesktopLayout(context);

    return treeAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: accent),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            SelectableText(
              'Erreur: $e',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(familyTreeProvider(personId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
              ),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
      data: (tree) {
        if (!desktop) {
          // Mobile: canvas seul + FABs
          return Stack(
            children: [
              TreeCanvas(tree: tree, personId: personId),
              Positioned(
                bottom: 16,
                left: 16,
                child: FloatingActionButton.small(
                  heroTag: 'addParent',
                  onPressed: () => _showAddDialog(context, ref, isParent: true),
                  backgroundColor: accent,
                  child: const Icon(Icons.person_add_alt_1, size: 18),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 64,
                child: FloatingActionButton.small(
                  heroTag: 'addChild',
                  onPressed: () => _showAddDialog(context, ref, isParent: false),
                  backgroundColor: accent,
                  child: const Icon(Icons.child_care, size: 18),
                ),
              ),
            ],
          );
        }

        // Desktop: 3-column layout
        return Row(
          children: [
            // ── Left panel ──
            GenealogyLeftPanel(tree: tree),
            const VerticalDivider(width: 1, color: T.border),

            // ── Center: canvas ──
            Expanded(
              child: TreeCanvas(
                tree: tree,
                personId: personId,
                onAddParent: () => _showAddDialog(context, ref, isParent: true),
                onAddChild: () => _showAddDialog(context, ref, isParent: false),
                onAddUnion: () => _showUnionDialog(context, ref, tree),
                onExport: () {
                  // TODO: export tree (PDF, image, etc.)
                },
              ),
            ),

            const VerticalDivider(width: 1, color: T.border),
            // ── Right panel ──
            GenealogyRightPanel(tree: tree, personId: personId),
          ],
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, {required bool isParent}) {
    // Use the selected person if any, otherwise fall back to the subject
    final selectedId = ref.read(treeViewProvider).selectedPersonId ?? personId;
    showDialog(
      context: context,
      builder: (_) => AddPersonDialog(personId: selectedId, isParent: isParent),
    );
  }

  void _showUnionDialog(BuildContext context, WidgetRef ref, FamilyTree tree) {
    final selectedId = ref.read(treeViewProvider).selectedPersonId;
    final allPersons = [
      tree.subject,
      ...tree.father,
      ...tree.mother,
      ...tree.paternalGP,
      ...tree.maternalGP,
      ...tree.siblings.map((s) => s.person),
      ...tree.children,
      ...tree.uncles,
    ];
    final person = selectedId != null
        ? allPersons.where((p) => p.id == selectedId).firstOrNull ?? tree.subject
        : tree.subject;

    // Defer to next frame to avoid mouse_tracker assertion on Flutter Web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AddUnionDialog(
          person: person,
          tree: tree,
          treeOwnerId: personId,
        ),
      );
    });
  }
}

// ── Error View ──

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
