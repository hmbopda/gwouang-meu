import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/messages/messages_providers.dart';
import 'package:gwangmeu/shared/models/chat_group_model.dart';

/// Messages — liste des conversations (#3a).
/// Destination de premier niveau : aperçu, heure mono, badge non-lu ember,
/// tag mono (village · type), segmenté Villages / Directs.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  bool _directs = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final conversationsAsync = ref.watch(myConversationsProvider);

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

            // ── Segmenté Villages / Directs ──
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
                    _segment('Villages', !_directs,
                        () => setState(() => _directs = false)),
                    _segment('Directs', _directs,
                        () => setState(() => _directs = true)),
                  ],
                ),
              ),
            ),

            // ── Liste ──
            Expanded(
              child: conversationsAsync.when(
                loading: () => Center(
                    child: CircularProgressIndicator(color: t.goldText)),
                error: (e, _) => _emptyState(t,
                    'Impossible de charger vos conversations.\nTirez pour réessayer.'),
                data: (conversations) {
                  var list = conversations
                      .where((c) => c.isDirect == _directs)
                      .toList();
                  if (_query.isNotEmpty) {
                    final q = _query.toLowerCase();
                    list = list
                        .where((c) =>
                            c.group.name.toLowerCase().contains(q) ||
                            c.villageName.toLowerCase().contains(q))
                        .toList();
                  }
                  if (list.isEmpty) {
                    return RefreshIndicator(
                      color: t.goldText,
                      onRefresh: () =>
                          ref.refresh(myConversationsProvider.future),
                      child: ListView(
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.sizeOf(context).height * 0.25),
                          _emptyState(
                              t,
                              _directs
                                  ? 'Aucun message direct pour le moment'
                                  : 'Rejoignez un village pour rejoindre ses conversations'),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: t.goldText,
                    onRefresh: () =>
                        ref.refresh(myConversationsProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) =>
                          _ConversationRow(conversation: list[i], index: i),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    final t = GwTokens.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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

  Widget _emptyState(GwTokens t, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.forum, size: 48, color: t.stoneFaint),
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

  void _showNewMessageHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ouvrez un village pour démarrer une conversation',
          style: GwType.ui(fontSize: 14, color: GwTokens.dark.stone),
        ),
      ),
    );
  }
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
    final tint = _tints[index % _tints.length];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(
          Routes.conversation(g.id),
          extra: <String, Object>{
            'group': g,
            'villageName': conversation.villageName,
          },
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Tuile initiale teintée
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                  style: GwType.display(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0C0B0F)),
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
                      '${conversation.villageName.toUpperCase()} · ${_typeLabel(g)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.mono(
                          fontSize: 11,
                          color: t.sageText,
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

  String _typeLabel(ChatGroupModel g) {
    switch (g.type.toUpperCase()) {
      case 'DM':
      case 'DIRECT':
        return 'DIRECT';
      case 'PRIVATE':
        return 'PRIVÉ';
      default:
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
