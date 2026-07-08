import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/messages/messages_providers.dart';

/// Messages — liste des conversations (#3a).
/// Destination de premier niveau : aperçu, heure mono, tag mono
/// (portée · type), segmenté **Villages / Famille / Directs**.
enum _MsgTab { villages, family, directs }

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  _MsgTab _tab = _MsgTab.villages;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Messages',
                      style: GwType.display(fontSize: 22, color: t.stone),
                    ),
                  ),
                  Material(
                    color: t.inkLift,
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    child: InkWell(
                      onTap: () => _showNewMessageHint(context),
                      borderRadius: BorderRadius.circular(GwTokens.rBtn),
                      child: SizedBox(
                        width: GwTokens.tapTarget,
                        height: GwTokens.tapTarget,
                        child: Icon(Symbols.edit_square,
                            size: 22, color: t.goldText),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Recherche ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: SizedBox(
                height: 50,
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une conversation…',
                    prefixIcon:
                        Icon(Symbols.search, size: 20, color: t.stoneDim),
                  ),
                ),
              ),
            ),

            // ── Segmenté Villages / Famille / Directs ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: t.inkCard,
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                ),
                child: Row(
                  children: [
                    _segment('Villages', _MsgTab.villages),
                    _segment('Famille', _MsgTab.family),
                    _segment('Directs', _MsgTab.directs),
                  ],
                ),
              ),
            ),

            // ── Liste ──
            Expanded(
              child: _tab == _MsgTab.family
                  ? _FamilyList(query: _query)
                  : _VillageList(directs: _tab == _MsgTab.directs, query: _query),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, _MsgTab tab) {
    final t = GwTokens.of(context);
    final selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
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
              color: selected ? GwTokens.inkOnGold : t.stoneFaint,
            ),
          ),
        ),
      ),
    );
  }

  void _showNewMessageHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ouvrez un village ou votre lignée pour démarrer une conversation',
          style: GwType.ui(fontSize: 14, color: GwTokens.of(context).stone),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Liste Villages / Directs
// ─────────────────────────────────────────────────────────────

class _VillageList extends ConsumerWidget {
  const _VillageList({required this.directs, required this.query});

  final bool directs;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final async = ref.watch(myConversationsProvider);
    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.goldText)),
      error: (e, _) => _emptyState(t, Symbols.forum,
          'Impossible de charger vos conversations.\nTirez pour réessayer.'),
      data: (all) {
        var list = all.where((c) => c.isDirect == directs).toList();
        list = _filter(list, query);
        return _RefreshList(
          onRefresh: () => ref.refresh(myConversationsProvider.future),
          empty: directs
              ? 'Aucun message direct pour le moment'
              : 'Rejoignez un village pour rejoindre ses conversations',
          list: list,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Liste Famille
// ─────────────────────────────────────────────────────────────

class _FamilyList extends ConsumerWidget {
  const _FamilyList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final clan = ref.watch(myClanProvider).valueOrNull;
    final async = ref.watch(myFamilyConversationsProvider);
    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.goldText)),
      error: (e, _) => _emptyState(t, Symbols.family_history,
          'Impossible de charger vos discussions de famille.'),
      data: (all) {
        final list = _filter(all, query);
        if (list.isEmpty && (clan == null)) {
          return _emptyState(
            t,
            Symbols.family_history,
            'Renseignez votre clan dans votre lignée\n'
            'pour rejoindre la discussion de famille.',
          );
        }
        return _RefreshList(
          onRefresh: () =>
              ref.refresh(myFamilyConversationsProvider.future),
          empty: 'Aucune discussion de famille pour le moment',
          list: list,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Helpers de liste
// ─────────────────────────────────────────────────────────────

List<Conversation> _filter(List<Conversation> list, String query) {
  if (query.isEmpty) return list;
  final q = query.toLowerCase();
  return list
      .where((c) =>
          c.group.name.toLowerCase().contains(q) ||
          c.scopeLabel.toLowerCase().contains(q))
      .toList();
}

class _RefreshList extends StatelessWidget {
  const _RefreshList({
    required this.onRefresh,
    required this.empty,
    required this.list,
  });

  final Future<void> Function() onRefresh;
  final String empty;
  final List<Conversation> list;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    if (list.isEmpty) {
      return RefreshIndicator(
        color: t.goldText,
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
            _emptyState(t, Symbols.forum, empty),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: t.goldText,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, i) =>
            _ConversationRow(conversation: list[i], index: i),
      ),
    );
  }
}

Widget _emptyState(GwTokens t, IconData icon, String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: t.stoneFaint),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 14, color: t.stoneMid, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Rangée conversation
// ─────────────────────────────────────────────────────────────

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.index});

  final Conversation conversation;
  final int index;

  static const _tints = [
    GwTokens.gold,
    GwTokens.sage,
    GwTokens.azure,
    GwTokens.rose,
  ];

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final g = conversation.group;
    // Les discussions de famille sont teintées or (identité de lignée).
    final tint = conversation.isFamily
        ? GwTokens.gold
        : _tints[index % _tints.length];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(
          Routes.conversation(g.id),
          extra: <String, Object>{
            'group': g,
            'villageName': conversation.scopeLabel,
          },
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Tuile initiale teintée (icône famille pour les lignées)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: conversation.isFamily
                    ? const Icon(Symbols.family_history,
                        size: 24, color: GwTokens.inkOnGold)
                    : Text(
                        g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                        style: GwType.display(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: GwTokens.inkOnGold),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            g.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GwType.ui(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: t.stone),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _time(g.createdAt),
                          style: GwType.mono(
                              fontSize: 10,
                              color: t.stoneFaint,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      g.description?.isNotEmpty == true
                          ? g.description!
                          : '${g.memberCount} membres',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.ui(fontSize: 13, color: t.stoneDim),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${conversation.scopeLabel.toUpperCase()} · ${_typeLabel(conversation.kind)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.mono(
                          fontSize: 11,
                          color: conversation.isFamily
                              ? t.goldText
                              : t.sageText,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(ConversationKind kind) {
    switch (kind) {
      case ConversationKind.direct:
        return 'DIRECT';
      case ConversationKind.family:
        return 'FAMILLE';
      case ConversationKind.village:
        return 'GROUPE';
    }
  }

  String _time(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (now.difference(dt).inHours < 24 && now.day == dt.day) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('d MMM', 'fr').format(dt);
  }
}
