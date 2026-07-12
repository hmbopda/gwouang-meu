import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/messages/messages_providers.dart';

/// Messages — liste des conversations, refonte « messagerie » : en-tête serif,
/// recherche, filtres en pilules (Tous · Villages · Clans · Directs) et rangées
/// à avatar rond. Alimenté par les vraies conversations (villages + famille +
/// directs). Le tap ouvre le fil (conversation_screen).
enum _MsgFilter { tous, villages, clans, directs }

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  _MsgFilter _filter = _MsgFilter.tous;
  String _query = '';

  static const _labels = {
    _MsgFilter.tous: 'Tous',
    _MsgFilter.villages: 'Villages',
    _MsgFilter.clans: 'Clans',
    _MsgFilter.directs: 'Directs',
  };

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),

            // ── En-tête ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Messages',
                        style: GwType.display(fontSize: 24, color: t.stone)),
                  ),
                  Material(
                    color: t.goldBg,
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    child: InkWell(
                      onTap: () => _showNewMessageHint(context),
                      borderRadius: BorderRadius.circular(GwTokens.rBtn),
                      child: SizedBox(
                        width: GwTokens.tapTarget,
                        height: GwTokens.tapTarget,
                        child: Icon(Symbols.edit_square,
                            size: 21, color: t.goldText),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Recherche ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                style: GwType.ui(fontSize: 14, color: t.stone),
                decoration: InputDecoration(
                  hintText: 'Rechercher un message, une personne…',
                  hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
                  prefixIcon:
                      Icon(Symbols.search, size: 20, color: t.stoneDim),
                  filled: true,
                  fillColor: t.inkLift,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    borderSide: BorderSide(color: t.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    borderSide: const BorderSide(color: GwTokens.gold),
                  ),
                ),
              ),
            ),

            // ── Filtres en pilules ──
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final f in _MsgFilter.values) ...[
                    _pill(t, _labels[f]!, f),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Liste unifiée ──
            Expanded(child: _ConvList(filter: _filter, query: _query)),
          ],
        ),
      ),
    );
  }

  Widget _pill(GwTokens t, String label, _MsgFilter f) {
    final active = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? GwTokens.gold : t.inkLift,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
          border: Border.all(color: active ? GwTokens.gold : t.line),
        ),
        child: Text(label,
            style: GwType.ui(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? GwTokens.inkOnGold : t.stoneMid)),
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
//  Liste unifiée (villages + famille + directs) filtrée
// ─────────────────────────────────────────────────────────────

class _ConvList extends ConsumerWidget {
  const _ConvList({required this.filter, required this.query});

  final _MsgFilter filter;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final convAsync = ref.watch(myConversationsProvider); // villages + directs
    final needFamily =
        filter == _MsgFilter.tous || filter == _MsgFilter.clans;
    final famAsync = needFamily
        ? ref.watch(myFamilyConversationsProvider)
        : const AsyncData<List<Conversation>>([]);

    // Chargement / erreur
    if (convAsync.isLoading || famAsync.isLoading) {
      return Center(child: CircularProgressIndicator(color: t.goldText));
    }
    if (convAsync.hasError && famAsync.hasError) {
      return _emptyState(t, Symbols.forum,
          'Impossible de charger vos conversations.\nTirez pour réessayer.');
    }
    final conv = convAsync.valueOrNull ?? const <Conversation>[];
    final fam = famAsync.valueOrNull ?? const <Conversation>[];

    List<Conversation> list;
    switch (filter) {
      case _MsgFilter.tous:
        list = [...conv, ...fam];
        break;
      case _MsgFilter.villages:
        list = conv.where((c) => c.kind == ConversationKind.village).toList();
        break;
      case _MsgFilter.directs:
        list = conv.where((c) => c.isDirect).toList();
        break;
      case _MsgFilter.clans:
        list = fam;
        break;
    }
    // Tri antéchronologique (plus récent d'abord).
    list.sort((a, b) => (b.group.createdAt ?? DateTime(1970))
        .compareTo(a.group.createdAt ?? DateTime(1970)));
    list = _filter(list, query);

    final emptyMsg = switch (filter) {
      _MsgFilter.directs => 'Aucun message direct pour le moment',
      _MsgFilter.clans => 'Renseignez votre clan dans votre lignée\n'
          'pour rejoindre la discussion de famille.',
      _MsgFilter.villages =>
        'Rejoignez un village pour accéder à ses conversations',
      _MsgFilter.tous => 'Aucune conversation pour le moment',
    };

    return RefreshIndicator(
      color: t.goldText,
      onRefresh: () async {
        ref.invalidate(myConversationsProvider);
        ref.invalidate(myFamilyConversationsProvider);
      },
      child: list.isEmpty
          ? ListView(children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
              _emptyState(t, Symbols.forum, emptyMsg),
            ])
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, i) =>
                  _ConversationRow(conversation: list[i], index: i),
            ),
    );
  }
}

List<Conversation> _filter(List<Conversation> list, String query) {
  if (query.isEmpty) return list;
  final q = query.toLowerCase();
  return list
      .where((c) =>
          c.group.name.toLowerCase().contains(q) ||
          c.scopeLabel.toLowerCase().contains(q))
      .toList();
}

Widget _emptyState(GwTokens t, IconData icon, String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: t.stoneFaint),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GwType.ui(fontSize: 14, color: t.stoneMid, height: 1.5)),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Rangée conversation — avatar rond teinté, nom, aperçu, heure
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
    final tint =
        conversation.isFamily ? GwTokens.gold : _tints[index % _tints.length];
    final preview = (g.description?.isNotEmpty == true)
        ? g.description!
        : '${g.memberCount} membre${g.memberCount > 1 ? 's' : ''}';

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              // Avatar rond teinté (icône famille pour les lignées).
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: tint.withValues(alpha: 0.5)),
                ),
                alignment: Alignment.center,
                child: conversation.isFamily
                    ? Icon(Symbols.family_history, size: 23, color: tint)
                    : Text(
                        g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                        style: GwType.display(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: tint),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GwType.ui(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: t.stone)),
                        ),
                        const SizedBox(width: 8),
                        Text(_time(g.createdAt),
                            style: GwType.mono(
                                fontSize: 10,
                                color: t.stoneFaint,
                                letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(fontSize: 13, color: t.stoneDim)),
                    const SizedBox(height: 4),
                    Text(
                      '${conversation.scopeLabel.toUpperCase()} · ${_typeLabel(conversation.kind)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.mono(
                          fontSize: 9.5,
                          letterSpacing: 0.8,
                          color:
                              conversation.isFamily ? t.goldText : t.sageText),
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
