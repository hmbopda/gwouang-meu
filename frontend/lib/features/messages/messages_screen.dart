import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/chat/direct_chat.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/features/messages/conversation_screen.dart';
import 'package:gwangmeu/features/messages/messages_providers.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';

/// Messages — refonte « messagerie ». Mobile : liste → navigation vers le fil.
/// Desktop/web : split 3 colonnes (liste · fil embarqué · panneau contact).
/// Alimenté par les vraies conversations (villages + famille + directs).
enum _MsgFilter { tous, villages, clans, directs }

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  _MsgFilter _filter = _MsgFilter.tous;
  String _query = '';
  Conversation? _selected; // desktop split

  static const _labels = {
    _MsgFilter.tous: 'Tous',
    _MsgFilter.villages: 'Villages',
    _MsgFilter.clans: 'Clans',
    _MsgFilter.directs: 'Directs',
  };

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final desktop = isDesktopLayout(context);

    if (desktop) {
      return Container(
        color: t.ink,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 340, child: _listColumn(t, desktop: true)),
            Container(width: 1, color: t.line),
            Expanded(child: _thread(t)),
            Container(width: 1, color: t.line),
            SizedBox(width: 300, child: _ContextPanel(conversation: _selected)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(child: _listColumn(t, desktop: false)),
    );
  }

  Widget _listColumn(GwTokens t, {required bool desktop}) {
    return Column(
      children: [
        if (!desktop) const GwWeaveBand(),
        _header(t),
        _search(t),
        _filters(t),
        const SizedBox(height: 12),
        Expanded(
          child: _ConvList(
            filter: _filter,
            query: _query,
            selectedId: desktop ? _selected?.group.id : null,
            onSelect:
                desktop ? (c) => setState(() => _selected = c) : null,
          ),
        ),
      ],
    );
  }

  Widget _header(GwTokens t) => Padding(
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
                onTap: () => _openNewMessage(context),
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                child: SizedBox(
                  width: GwTokens.tapTarget,
                  height: GwTokens.tapTarget,
                  child:
                      Icon(Symbols.edit_square, size: 21, color: t.goldText),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _search(GwTokens t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: TextField(
          onChanged: (v) => setState(() => _query = v.trim()),
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: InputDecoration(
            hintText: 'Rechercher un message, une personne…',
            hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
            prefixIcon: Icon(Symbols.search, size: 20, color: t.stoneDim),
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
      );

  Widget _filters(GwTokens t) => SizedBox(
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
      );

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

  Widget _thread(GwTokens t) {
    final sel = _selected;
    if (sel == null) {
      return Container(
        color: t.inkDeep,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.forum, size: 54, color: t.stoneFaint),
            const SizedBox(height: 14),
            Text('Sélectionnez une conversation',
                style: GwType.ui(fontSize: 15, color: t.stoneMid)),
          ],
        ),
      );
    }
    return ConversationScreen(
      key: ValueKey(sel.group.id),
      groupId: sel.group.id,
      group: sel.group,
      villageName: sel.scopeLabel,
      embedded: true,
    );
  }

  void _openNewMessage(BuildContext context) {
    showGwDialog(context, builder: (_) => const _NewMessageSheet());
  }
}

// ─────────────────────────────────────────────────────────────
//  Nouveau message — recherche d'un contact LIÉ puis ouverture d'un DM
// ─────────────────────────────────────────────────────────────

class _NewMessageSheet extends ConsumerStatefulWidget {
  const _NewMessageSheet();

  @override
  ConsumerState<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends ConsumerState<_NewMessageSheet> {
  String _query = '';
  bool _opening = false;

  Future<void> _open(ChatContact c) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final group = await ref.read(directChatOpenerProvider).openWith(c.userId);
      if (!mounted) return;
      // Rafraîchir la liste pour que le nouveau DM y apparaisse.
      ref.invalidate(myDirectConversationsProvider);
      Navigator.of(context).maybePop();
      context.push(
        Routes.conversation(group.id),
        extra: <String, Object>{'group': group, 'villageName': c.displayName},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _opening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GwTokens.ember,
          content: Text("Impossible d'ouvrir la conversation",
              style: GwType.ui(fontSize: 14, color: GwTokens.inkOnGold)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final contactsAsync = ref.watch(chatContactsProvider(_query));
    return GwDialog(
      title: 'Nouveau message',
      subtitle: 'Écrivez à une personne liée (famille, mariage, clan, village)',
      icon: Symbols.edit_square,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: gwInputDecoration(context,
                hint: 'Rechercher une personne…',
                prefixIcon: Symbols.search),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: contactsAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: t.goldText)),
              error: (_, __) => Center(
                child: Text('Erreur de chargement',
                    style: GwType.ui(fontSize: 13, color: t.stoneDim)),
              ),
              data: (contacts) {
                if (contacts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _query.isEmpty
                            ? 'Aucun contact lié pour l’instant.\n'
                                'Rejoignez un village ou complétez votre lignée.'
                            : 'Aucun résultat pour « $_query ».',
                        textAlign: TextAlign.center,
                        style: GwType.ui(
                            fontSize: 13, color: t.stoneMid, height: 1.5),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (_, i) => _contactRow(t, contacts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(GwTokens t, ChatContact c) {
    final name = c.displayName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasAvatar = c.avatarUrl != null && c.avatarUrl!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: _opening ? null : () => _open(c),
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: t.goldBg,
                backgroundImage: hasAvatar ? NetworkImage(c.avatarUrl!) : null,
                child: hasAvatar
                    ? null
                    : Text(initial,
                        style:
                            GwType.display(fontSize: 15, color: t.goldText)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name.isEmpty ? 'Membre' : name,
                  style: GwType.ui(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: t.stone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Symbols.chevron_right, size: 18, color: t.stoneFaint),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Liste unifiée (villages + famille + directs) filtrée
// ─────────────────────────────────────────────────────────────

class _ConvList extends ConsumerWidget {
  const _ConvList({
    required this.filter,
    required this.query,
    this.onSelect,
    this.selectedId,
  });

  final _MsgFilter filter;
  final String query;
  final void Function(Conversation)? onSelect;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final convAsync = ref.watch(myConversationsProvider); // villages + directs village
    final directAsync = ref.watch(myDirectConversationsProvider); // DM globaux
    final needFamily =
        filter == _MsgFilter.tous || filter == _MsgFilter.clans;
    final famAsync = needFamily
        ? ref.watch(myFamilyConversationsProvider)
        : const AsyncData<List<Conversation>>([]);

    if (convAsync.isLoading || famAsync.isLoading) {
      return Center(child: CircularProgressIndicator(color: t.goldText));
    }
    if (convAsync.hasError && famAsync.hasError) {
      return _emptyState(t, Symbols.forum,
          'Impossible de charger vos conversations.\nTirez pour réessayer.');
    }
    // Les DM globaux (/my-groups) sont fusionnés au mieux : s'ils sont en
    // erreur ou en cours (backend pas encore déployé), la liste ne bloque pas.
    final conv = <Conversation>[
      ...(convAsync.valueOrNull ?? const <Conversation>[]),
      ...(directAsync.valueOrNull ?? const <Conversation>[]),
    ];
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
    list.sort((a, b) => (b.group.createdAt ?? DateTime(1970))
        .compareTo(a.group.createdAt ?? DateTime(1970)));
    list = _filterByQuery(list, query);

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
        ref.invalidate(myDirectConversationsProvider);
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
              itemBuilder: (context, i) {
                final c = list[i];
                return _ConversationRow(
                  conversation: c,
                  index: i,
                  selected: selectedId != null && selectedId == c.group.id,
                  onTap: () {
                    if (onSelect != null) {
                      onSelect!(c);
                    } else {
                      context.push(
                        Routes.conversation(c.group.id),
                        extra: <String, Object>{
                          'group': c.group,
                          'villageName': c.scopeLabel,
                        },
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

List<Conversation> _filterByQuery(List<Conversation> list, String query) {
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
  const _ConversationRow({
    required this.conversation,
    required this.index,
    required this.onTap,
    this.selected = false,
  });

  final Conversation conversation;
  final int index;
  final VoidCallback onTap;
  final bool selected;

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
      color: selected ? t.goldBg : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? t.goldLine : Colors.transparent),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
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

// ─────────────────────────────────────────────────────────────
//  Panneau contact (colonne droite desktop) — infos RÉELLES du groupe
// ─────────────────────────────────────────────────────────────

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.conversation});
  final Conversation? conversation;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final c = conversation;
    if (c == null) {
      return Container(color: t.inkCard);
    }
    final g = c.group;
    final tint = c.isFamily ? GwTokens.gold : GwTokens.sage;

    return Container(
      color: t.inkCard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          // Avatar + nom + portée.
          Center(
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: tint.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: c.isFamily
                      ? Icon(Symbols.family_history, size: 34, color: tint)
                      : Text(
                          g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                          style: GwType.display(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: tint),
                        ),
                ),
                const SizedBox(height: 12),
                Text(g.name,
                    textAlign: TextAlign.center,
                    style: GwType.display(fontSize: 19, color: t.stone)),
                const SizedBox(height: 4),
                Text(
                    '${c.scopeLabel.toUpperCase()} · ${g.memberCount} MEMBRE${g.memberCount > 1 ? 'S' : ''}',
                    textAlign: TextAlign.center,
                    style: GwType.mono(
                        fontSize: 9.5, letterSpacing: 1, color: t.stoneDim)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description réelle si présente.
          if (g.description?.isNotEmpty == true) ...[
            _panelLabel(t, 'À propos'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.inkLift,
                borderRadius: BorderRadius.circular(GwTokens.rCard),
                border: Border.all(color: t.line),
              ),
              child: Text(g.description!,
                  style: GwType.ui(
                      fontSize: 13, color: t.stoneMid, height: 1.5)),
            ),
            const SizedBox(height: 20),
          ],

          // Action : ouvrir en plein écran.
          _panelAction(
            t,
            icon: Symbols.open_in_full,
            label: 'Ouvrir en plein écran',
            onTap: () => context.push(
              Routes.conversation(g.id),
              extra: <String, Object>{
                'group': g,
                'villageName': c.scopeLabel,
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelLabel(GwTokens t, String text) => Text(text.toUpperCase(),
      style: GwType.mono(fontSize: 10, letterSpacing: 1.5, color: t.stoneDim));

  Widget _panelAction(GwTokens t,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.inkLift,
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            border: Border.all(color: t.line),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: t.goldText),
            const SizedBox(width: 10),
            Text(label,
                style: GwType.ui(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: t.stone)),
          ]),
        ),
      ),
    );
  }
}
