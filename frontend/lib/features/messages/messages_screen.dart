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
import 'package:gwangmeu/features/presence/presence_service.dart';
import 'package:gwangmeu/shared/models/chat_group_model.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';

/// Messages — boîte de réception UNIQUE, façon Messenger. Toutes les
/// conversations de l'utilisateur (DM + chats de village + chats de
/// famille/clan) sont fusionnées en une seule liste triée par activité
/// récente. Mobile : liste → navigation vers le fil. Desktop/web : split
/// 3 colonnes (liste · fil embarqué · panneau contact).
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String _query = '';
  Conversation? _selected; // desktop split

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
        const SizedBox(height: 6),
        Expanded(
          child: _ConvList(
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
            // Nouveau message (DM) — le « + » de la boîte unique.
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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: TextField(
          onChanged: (v) => setState(() => _query = v.trim()),
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: InputDecoration(
            hintText: 'Rechercher une conversation…',
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
//  Liste unifiée — villages + famille + directs, une seule boîte
// ─────────────────────────────────────────────────────────────

/// Date plancher pour trier les conversations sans `createdAt`.
final _epoch = DateTime.utc(1970);

class _ConvList extends ConsumerWidget {
  const _ConvList({
    required this.query,
    this.onSelect,
    this.selectedId,
  });

  final String query;
  final void Function(Conversation)? onSelect;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final convAsync = ref.watch(myConversationsProvider); // villages + DM village
    final directAsync = ref.watch(myDirectConversationsProvider); // DM globaux
    final famAsync = ref.watch(myFamilyConversationsProvider); // famille / clan

    final conv = convAsync.valueOrNull;
    final direct = directAsync.valueOrNull;
    final fam = famAsync.valueOrNull;
    final anyLoading =
        convAsync.isLoading || directAsync.isLoading || famAsync.isLoading;
    final noData = conv == null && direct == null && fam == null;

    // Tant qu'aucune source n'a répondu, on patiente. Ensuite on affiche ce
    // qui est dispo — une source en erreur (backend pas déployé) ne bloque pas.
    if (noData && anyLoading) {
      return Center(child: CircularProgressIndicator(color: t.goldText));
    }
    if (noData) {
      return RefreshIndicator(
        color: t.goldText,
        onRefresh: () async => _refresh(ref),
        child: ListView(children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          _emptyState(t, Symbols.forum,
              'Impossible de charger vos conversations.\nTirez pour réessayer.'),
        ]),
      );
    }

    // Fusion + déduplication par id de groupe (une même conversation peut
    // remonter de plusieurs sources), puis tri par activité récente.
    final byId = <String, Conversation>{};
    for (final c in [...?conv, ...?direct, ...?fam]) {
      byId.putIfAbsent(c.group.id, () => c);
    }
    var list = byId.values.toList()
      ..sort((a, b) => (b.group.createdAt ?? _epoch)
          .compareTo(a.group.createdAt ?? _epoch));
    list = _filterByQuery(list, query);

    return RefreshIndicator(
      color: t.goldText,
      onRefresh: () async => _refresh(ref),
      child: list.isEmpty
          ? ListView(children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
              _emptyState(
                t,
                Symbols.forum,
                query.isEmpty
                    ? 'Aucune conversation pour le moment'
                    : 'Aucun résultat pour « $query ».',
              ),
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

  void _refresh(WidgetRef ref) {
    ref.invalidate(myConversationsProvider);
    ref.invalidate(myDirectConversationsProvider);
    ref.invalidate(myFamilyConversationsProvider);
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
//  Rangée conversation — avatar (+ présence DM), nom, aperçu, heure, non-lus
// ─────────────────────────────────────────────────────────────

class _ConversationRow extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final g = conversation.group;
    final tint =
        conversation.isFamily ? GwTokens.gold : _tints[index % _tints.length];
    // Aperçu du dernier message : indisponible côté backend (ChatGroupDto ne
    // porte pas de dernier message) → repli sur la description ou le nombre de
    // membres.
    final preview = (g.description?.isNotEmpty == true)
        ? g.description!
        : '${g.memberCount} membre${g.memberCount > 1 ? 's' : ''}';
    final unread = conversation.unreadCount;

    // Présence : pastille verte pour un DM 1:1 dont l'autre membre est en ligne.
    // On ne résout le pair (via /members) QUE pour les conversations directes.
    var online = false;
    if (conversation.isDirect) {
      final peerId = ref.watch(directPeerIdProvider(g.id)).valueOrNull;
      if (peerId != null) {
        online = ref.watch(onlineUsersProvider).contains(peerId);
      }
    }

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
              _avatar(t, g, tint, online),
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
                                  fontWeight: unread > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: t.stone)),
                        ),
                        const SizedBox(width: 8),
                        Text(_time(g.createdAt),
                            style: GwType.mono(
                                fontSize: 10,
                                color: t.stoneFaint,
                                letterSpacing: 0.5)),
                        if (unread > 0) ...[
                          const SizedBox(width: 6),
                          _unreadBadge(unread),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(
                            fontSize: 13,
                            color: unread > 0 ? t.stoneMid : t.stoneDim)),
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

  Widget _avatar(GwTokens t, ChatGroupModel g, Color tint, bool online) {
    return Stack(
      clipBehavior: Clip.none,
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
                      fontSize: 19, fontWeight: FontWeight.w600, color: tint),
                ),
        ),
        // Pastille « en ligne » (DM 1:1 uniquement).
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: GwTokens.sage,
                shape: BoxShape.circle,
                border: Border.all(color: t.ink, width: 2.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _unreadBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GwTokens.ember,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: GwType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: GwTokens.inkOnGold),
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
