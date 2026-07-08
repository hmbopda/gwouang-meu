import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/verification/verification_provider.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/add_person_dialog.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/add_union_dialog.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/person_detail_popup.dart';
import 'package:gwangmeu/features/genealogy/widgets/right_panel/genealogy_right_panel.dart';
import 'package:gwangmeu/features/genealogy/widgets/right_panel/genealogy_story_panel.dart';
import 'package:gwangmeu/features/genealogy/widgets/river_view.dart';
import 'package:gwangmeu/features/genealogy/widgets/tree_canvas/tree_canvas.dart';

/// Lignées — « Rivière des générations » (#1d mobile, #2c desktop).
class GenealogyScreen extends ConsumerWidget {
  const GenealogyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final myPersonAsync = ref.watch(genealogyNotifierProvider);
    final desktop = isDesktopLayout(context);

    final body = myPersonAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.goldText)),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(genealogyNotifierProvider),
      ),
      data: (myPerson) => _GenealogyBody(personId: myPerson.id),
    );

    if (desktop) return body;

    return Scaffold(body: SafeArea(child: body));
  }
}

// ── Body principal ───────────────────────────────────────────

class _GenealogyBody extends ConsumerWidget {
  const _GenealogyBody({required this.personId});
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    // Racine effective de l'arbre : focus « centrer ici » sinon le sujet.
    final focusId = ref.watch(treeViewProvider.select((s) => s.focusPersonId));
    final rootId = focusId ?? personId;
    final treeAsync = ref.watch(familyTreeProvider(rootId));
    final desktop = isDesktopLayout(context);

    return treeAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.goldText)),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(familyTreeProvider(rootId)),
      ),
      data: (tree) => desktop
          ? _DesktopLayout(tree: tree, personId: rootId, subjectId: personId)
          : _MobileLayout(tree: tree, personId: rootId, subjectId: personId),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  MOBILE — Rivière des générations (#1d)
// ═════════════════════════════════════════════════════════════

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({
    required this.tree,
    required this.personId,
    required this.subjectId,
  });

  final FamilyTree tree;

  /// Racine effective affichée (sujet ou personne « centrée »).
  final String personId;

  /// Identité de l'utilisateur (« retour à moi » du fil d'Ariane).
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final mode = ref.watch(riverModeProvider);
    // Suggestion IA réelle (plus forte confidence, hors « Plus tard »).
    final suggestion = _bestSuggestion(
        tree, ref.watch(dismissedSuggestionsProvider));
    // Mutation optimiste : la branche confirmée compte immédiatement (+1).
    final aiConfirmed = suggestion != null &&
        ref.watch(confirmedSuggestionsProvider).contains(suggestion.id);
    final memberCount = _memberCount(tree) + (aiConfirmed ? 1 : 0);

    return Column(
      children: [
        const GwWeaveBand(),

        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lignée ${tree.subject.lastName}',
                      style: GwType.display(fontSize: 22, color: t.stone),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        '$memberCount membres',
                        if (tree.subject.clan != null &&
                            tree.subject.clan!.isNotEmpty)
                          'Clan ${tree.subject.clan}',
                      ].join(' · '),
                      style: GwType.ui(fontSize: 13, color: t.stoneFaint),
                    ),
                  ],
                ),
              ),
              Material(
                color: t.inkLift,
                borderRadius: BorderRadius.circular(GwTokens.rPill),
                child: InkWell(
                  onTap: () => showGwToast(
                      context, 'Mode récit — bientôt disponible'),
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                  child: Container(
                    height: GwTokens.tapTarget,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.auto_stories,
                            size: 18, color: t.goldText),
                        const SizedBox(width: 8),
                        Text(
                          'Récit',
                          style: GwType.ui(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: t.goldText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Toggle Rivière / Arbre / Liste ──
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: t.inkCard,
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
            ),
            child: Row(
              children: [
                _segment(context, ref, RiverMode.river, 'Rivière', mode),
                _segment(context, ref, RiverMode.tree, 'Arbre', mode),
                _segment(context, ref, RiverMode.list, 'Liste', mode),
              ],
            ),
          ),
        ),

        // ── Contenu ──
        Expanded(
          child: switch (mode) {
            RiverMode.river => GenealogyRiverView(
                tree: tree,
                suggestion: suggestion,
                aiConfirmed: aiConfirmed,
                onPersonTap: (p) => showDialog(
                  context: context,
                  builder: (_) => PersonDetailPopup(person: p),
                ),
                onVerifySuggestion: suggestion == null
                    ? null
                    : () => context.push(Routes.verify(suggestion.id)),
              ),
            RiverMode.tree => TreeCanvas(
                tree: tree,
                personId: personId,
                onAddParent: () =>
                    _showAddDialog(context, ref, isParent: true),
                onAddChild: () =>
                    _showAddDialog(context, ref, isParent: false),
              ),
            RiverMode.list => _ListMode(tree: tree),
          },
        ),

        // ── Barre d'action contextuelle ──
        Container(
          margin: const EdgeInsets.fromLTRB(22, 8, 22, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: t.inkCard,
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(GwTokens.rCard),
          ),
          child: Row(
            children: [
              _action(context, Symbols.person_add, 'Ajouter', primary: true,
                  onTap: () => _showAddMenu(context, ref)),
              _action(context, Symbols.mic, 'Récit audio',
                  onTap: () =>
                      showGwToast(context, 'Récits audio — bientôt')),
              _action(context, Symbols.share, 'Inviter',
                  onTap: () => showGwToast(context, 'Invitations — bientôt')),
              _action(context, Symbols.download, 'Exporter',
                  onTap: () => showGwToast(context, 'Export — bientôt')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segment(BuildContext context, WidgetRef ref, RiverMode value,
      String label, RiverMode current) {
    final t = GwTokens.of(context);
    final selected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(riverModeProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? GwTokens.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GwType.ui(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? const Color(0xFF0C0B0F) : t.stoneFaint,
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label,
      {bool primary = false, VoidCallback? onTap}) {
    final t = GwTokens.of(context);
    final color = primary ? t.goldText : t.stoneMid;
    return Expanded(
      child: Material(
        color: primary ? t.goldBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GwType.ui(
                      fontSize: 10.5,
                      fontWeight:
                          primary ? FontWeight.w600 : FontWeight.w400,
                      color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.inkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            _sheetItem(sheetCtx, Symbols.person_add, 'Ajouter un parent', () {
              Navigator.pop(sheetCtx);
              _showAddDialog(context, ref, isParent: true);
            }),
            _sheetItem(sheetCtx, Symbols.child_care, 'Ajouter un enfant', () {
              Navigator.pop(sheetCtx);
              _showAddDialog(context, ref, isParent: false);
            }),
            _sheetItem(sheetCtx, Symbols.favorite, 'Ajouter une union', () {
              Navigator.pop(sheetCtx);
              _showUnionDialog(context, ref, tree);
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final t = GwTokens.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: t.goldText),
      title: Text(label,
          style: GwType.ui(
              fontSize: 15, fontWeight: FontWeight.w600, color: t.stone)),
      minTileHeight: 52,
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref,
      {required bool isParent}) {
    final selectedId = ref.read(treeViewProvider).selectedPersonId ?? personId;
    showDialog(
      context: context,
      builder: (_) => AddPersonDialog(personId: selectedId, isParent: isParent),
    );
  }

  void _showUnionDialog(BuildContext context, WidgetRef ref, FamilyTree tree) {
    final selectedId = ref.read(treeViewProvider).selectedPersonId;
    final person = selectedId != null
        ? _allPersons(tree).where((p) => p.id == selectedId).firstOrNull ??
            tree.subject
        : tree.subject;

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

// ═════════════════════════════════════════════════════════════
//  DESKTOP — L'arbre signature (#2c)
// ═════════════════════════════════════════════════════════════

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout({
    required this.tree,
    required this.personId,
    required this.subjectId,
  });

  final FamilyTree tree;

  /// Racine effective affichée (sujet ou personne « centrée »).
  final String personId;

  /// Identité de l'utilisateur (« retour à moi » du fil d'Ariane).
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final selectedId =
        ref.watch(treeViewProvider.select((s) => s.selectedPersonId));
    // Suggestion IA réelle (plus forte confidence, hors « Plus tard »).
    final suggestion = _bestSuggestion(
        tree, ref.watch(dismissedSuggestionsProvider));
    final aiConfirmed = suggestion != null &&
        ref.watch(confirmedSuggestionsProvider).contains(suggestion.id);
    final memberCount = _memberCount(tree) + (aiConfirmed ? 1 : 0);

    return Column(
      children: [
        // ── Topbar léger 60 px ──
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.line)),
          ),
          child: Row(
            children: [
              Text(
                'Lignée ${tree.subject.lastName}',
                style: GwType.display(fontSize: 19, color: t.stone),
              ),
              const SizedBox(width: 16),
              Text(
                [
                  '$memberCount membres',
                  if (tree.subject.clan != null &&
                      tree.subject.clan!.isNotEmpty)
                    'Clan ${tree.subject.clan}',
                ].join(' · '),
                style: GwType.ui(fontSize: 13, color: t.stoneFaint),
              ),
              const Spacer(),
              _pill(
                context,
                icon: Symbols.auto_stories,
                label: 'Mode récit',
                outlined: true,
                onTap: () =>
                    showGwToast(context, 'Mode récit — bientôt disponible'),
              ),
              const SizedBox(width: 10),
              _pill(
                context,
                icon: Symbols.person_add,
                label: 'Ajouter',
                onTap: () => _showAddDialog(context, ref, isParent: true),
              ),
            ],
          ),
        ),

        // ── Canvas + panneau Récit ──
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: TreeCanvas(
                  tree: tree,
                  personId: personId,
                  showLegend: true,
                  onAddParent: () =>
                      _showAddDialog(context, ref, isParent: true),
                  onAddChild: () =>
                      _showAddDialog(context, ref, isParent: false),
                  onAddUnion: () => _showUnionDialog(context, ref),
                  onExport: () =>
                      showGwToast(context, 'Export — bientôt disponible'),
                ),
              ),
              VerticalDivider(width: 1, color: t.line),
              // Récit par défaut ; détail personne quand une carte est choisie
              selectedId == null
                  ? GenealogyStoryPanel(
                      tree: tree,
                      suggestion: suggestion,
                      suggestionConfirmed: aiConfirmed,
                      onVerifySuggestion: suggestion == null
                          ? null
                          : () =>
                              context.push(Routes.verify(suggestion.id)),
                      onDismissSuggestion: suggestion == null
                          ? null
                          : () => ref
                              .read(dismissedSuggestionsProvider.notifier)
                              .update((s) => {...s, suggestion.id}),
                    )
                  : GenealogyRightPanel(tree: tree, personId: personId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    final t = GwTokens.of(context);
    final fg = outlined ? t.goldText : const Color(0xFF0C0B0F);
    return Material(
      color: outlined ? t.goldBg : GwTokens.gold,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Container(
          height: GwTokens.tapTarget,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                  border: Border.all(
                      color: GwTokens.gold.withValues(alpha: 0.35)),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: GwType.ui(
                    fontSize: 13.5,
                    fontWeight: outlined ? FontWeight.w600 : FontWeight.w700,
                    color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref,
      {required bool isParent}) {
    final selectedId = ref.read(treeViewProvider).selectedPersonId ?? personId;
    showDialog(
      context: context,
      builder: (_) => AddPersonDialog(personId: selectedId, isParent: isParent),
    );
  }

  void _showUnionDialog(BuildContext context, WidgetRef ref) {
    final selectedId = ref.read(treeViewProvider).selectedPersonId;
    final person = selectedId != null
        ? _allPersons(tree).where((p) => p.id == selectedId).firstOrNull ??
            tree.subject
        : tree.subject;

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

// ═════════════════════════════════════════════════════════════
//  Liste (mode mobile)
// ═════════════════════════════════════════════════════════════

class _ListMode extends StatelessWidget {
  const _ListMode({required this.tree});

  final FamilyTree tree;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final sections = <(String, List<dynamic>)>[
      ('GRANDS-PARENTS', [...tree.paternalGP, ...tree.maternalGP]),
      ('PARENTS', [...tree.father, ...tree.mother]),
      ('ONCLES & TANTES', tree.uncles),
      ('VOUS & FRATRIE', [tree.subject, ...tree.siblings.map((s) => s.person)]),
      ('ENFANTS', tree.children),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
      children: [
        for (final (label, persons) in sections)
          if (persons.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Text(
                label,
                style: GwType.mono(
                    fontSize: 10, letterSpacing: 2, color: t.stoneFaint),
              ),
            ),
            for (final p in persons)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: t.inkCard,
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                ),
                child: ListTile(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => PersonDetailPopup(person: p),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: t.inkLift,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: p.id == tree.subject.id
                            ? GwTokens.gold
                            : p.isAlive
                                ? GwTokens.gold.withValues(alpha: 0.5)
                                : t.stoneFaint,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p.firstName.isNotEmpty
                          ? p.firstName[0].toUpperCase()
                          : '?',
                      style: GwType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.stone),
                    ),
                  ),
                  title: Text(
                    '${p.firstName} ${p.lastName}${p.isAlive ? '' : ' ✦'}',
                    style: GwType.ui(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: t.stone),
                  ),
                  subtitle: p.clan != null && p.clan!.isNotEmpty
                      ? Text('Clan ${p.clan}',
                          style:
                              GwType.ui(fontSize: 12.5, color: t.stoneDim))
                      : null,
                  minTileHeight: 56,
                ),
              ),
          ],
      ],
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────

/// Suggestion IA à afficher : la plus forte confidence parmi
/// `tree.pendingSuggestions`, en excluant celles écartées (« Plus tard »).
AiSuggestion? _bestSuggestion(FamilyTree tree, Set<String> dismissed) {
  AiSuggestion? best;
  for (final s in tree.pendingSuggestions) {
    if (dismissed.contains(s.id)) continue;
    if (best == null || s.confidence > best.confidence) best = s;
  }
  return best;
}

int _memberCount(FamilyTree tree) {
  return 1 +
      tree.father.length +
      tree.mother.length +
      tree.paternalGP.length +
      tree.maternalGP.length +
      tree.siblings.length +
      tree.children.length +
      tree.uncles.length;
}

List<dynamic> _allPersons(FamilyTree tree) => [
      tree.subject,
      ...tree.father,
      ...tree.mother,
      ...tree.paternalGP,
      ...tree.maternalGP,
      ...tree.siblings.map((s) => s.person),
      ...tree.children,
      ...tree.uncles,
    ];

// ── Error View ──

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.error, color: t.emberText, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GwType.ui(fontSize: 14, color: t.stoneMid),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Symbols.refresh, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, GwTokens.tapTarget),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
