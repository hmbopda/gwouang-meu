import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/chat/chat_notifier.dart';
import 'package:gwangmeu/shared/models/chat_group_model.dart';
import 'package:gwangmeu/shared/models/chat_message_model.dart';

/// Conversation de groupe (#3b) — bulles 18 px, rôles inline, message vocal
/// avec forme d'onde, micro = action primaire (48 px or), suggestion IA
/// « Traduire en Bassa » en pilule pointillée sage.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    super.key,
    required this.groupId,
    this.group,
    this.villageName,
    this.embedded = false,
  });

  final String groupId;
  final ChatGroupModel? group;
  final String? villageName;

  /// Embarqué dans le split 3 colonnes desktop : pas de Scaffold, ni bande
  /// tissée, ni flèche retour (la liste reste visible à côté).
  final bool embedded;

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText = false;
  bool _translateDismissed = false;
  RealtimeChannel? _channel;
  Timer? _pollTimer;
  bool _realtimeLive = false;

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(() {
      final has = _inputCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _subscribeRealtime();
    _startPolling();
  }

  /// Temps réel : à chaque message inséré dans ce groupe, on recharge la liste
  /// (enrichie du nom/avatar de l'expéditeur). RLS côté Supabase : on ne reçoit
  /// que les messages des groupes dont on est membre — le socket Realtime doit
  /// donc porter le JWT de l'utilisateur, sinon `auth.uid()` est nul et la
  /// diffusion est bloquée. On force donc l'auth avant de s'abonner.
  void _subscribeRealtime() {
    final client = Supabase.instance.client;
    final token = client.auth.currentSession?.accessToken;
    if (token != null) {
      client.realtime.setAuth(token);
    }
    _channel = client
        .channel('chat_messages:${widget.groupId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: widget.groupId,
          ),
          callback: (_) => _refreshMessages(),
        )
        .subscribe((status, error) {
          _realtimeLive = status == RealtimeSubscribeStatus.subscribed;
          // Realtime confirmé → filet de sécurité lent. Sinon (erreur / socket
          // bloqué) → sondage rapide pour que les messages arrivent quand même
          // sans rafraîchir manuellement.
          _startPolling();
        });
  }

  /// Filet de sécurité : recharge périodiquement, pour qu'un message ne reste
  /// jamais invisible faute de rafraîchissement, même si le WebSocket Realtime
  /// est bloqué (réseau d'entreprise, proxy…). Instantané via Realtime quand il
  /// fonctionne ; ce sondage n'est qu'un secours.
  void _startPolling() {
    _pollTimer?.cancel();
    final interval = _realtimeLive
        ? const Duration(seconds: 20)
        : const Duration(seconds: 3);
    _pollTimer = Timer.periodic(interval, (_) => _refreshMessages());
  }

  void _refreshMessages() {
    if (!mounted) return;
    ref.invalidate(chatMessagesNotifierProvider(widget.groupId));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    final channel = _channel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final messagesAsync =
        ref.watch(chatMessagesNotifierProvider(widget.groupId));
    final myId = Supabase.instance.client.auth.currentUser?.id;

    final body = Column(
      children: [
        if (!widget.embedded) const GwWeaveBand(),
        _header(t),
        Expanded(
          child: messagesAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: t.goldText)),
            error: (e, _) => Center(
              child: Text('Erreur de chargement',
                  style: GwType.ui(fontSize: 14, color: t.stoneMid)),
            ),
            data: (messages) => _messageList(t, messages, myId),
          ),
        ),
        _inputBar(t),
      ],
    );

    if (widget.embedded) {
      return Container(color: t.ink, child: body);
    }
    return Scaffold(body: SafeArea(child: body));
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _header(GwTokens t) {
    final name = widget.group?.name ?? 'Conversation';
    final members = widget.group?.memberCount ?? 0;
    final subtitle = [
      if (widget.villageName != null) widget.villageName!,
      if (members > 0) '$members membres',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          if (!widget.embedded) ...[
            SizedBox(
              width: GwTokens.tapTarget,
              height: GwTokens.tapTarget,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Symbols.arrow_back, size: 24, color: t.stone),
                tooltip: 'Retour',
              ),
            ),
            const SizedBox(width: 4),
          ],
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: GwTokens.gold,
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GwType.display(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: GwTokens.inkOnGold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.ui(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.stone),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(fontSize: 12, color: t.sageText),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: GwTokens.tapTarget,
            height: GwTokens.tapTarget,
            child: IconButton(
              onPressed: () {},
              icon: Icon(Symbols.call, size: 22, color: t.stoneMid),
              tooltip: 'Appeler',
            ),
          ),
        ],
      ),
    );
  }

  // ── Messages ───────────────────────────────────────────────

  Widget _messageList(
      GwTokens t, List<ChatMessageModel> messages, String? myId) {
    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: messages.length + 2,
      itemBuilder: (context, index) {
        // index 0 (bas de liste) : suggestion IA traduction
        if (index == 0) {
          return _translateDismissed
              ? const SizedBox.shrink()
              : _translatePill(t);
        }
        // dernier item (haut) : chip de date
        if (index == messages.length + 1) {
          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: t.inkCard,
                borderRadius: BorderRadius.circular(GwTokens.rPill),
              ),
              child: Text(
                _dayLabel(messages),
                style: GwType.mono(
                    fontSize: 10, letterSpacing: 1.5, color: t.stoneFaint),
              ),
            ),
          );
        }

        // Messages : liste inversée → le plus récent en premier
        final ordered = messages.reversed.toList();
        final m = ordered[index - 1];
        final isMine = myId != null && m.senderId == myId;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: isMine ? _sentBubble(t, m) : _receivedBubble(t, m),
        );
      },
    );
  }

  Widget _receivedBubble(GwTokens t, ChatMessageModel m) {
    final senderColor = _senderColor(t, m.senderId);
    final isVoice = m.type.toUpperCase() == 'AUDIO' ||
        m.type.toUpperCase() == 'VOICE';

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.86),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: senderColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                (m.senderName ?? '?').isNotEmpty
                    ? m.senderName![0].toUpperCase()
                    : '?',
                style: GwType.ui(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: senderColor),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      m.senderName ?? 'Membre',
                      style: GwType.ui(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: senderColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: t.inkLift,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                    child: isVoice
                        ? _voiceContent(t)
                        : Text(
                            m.content,
                            style: GwType.ui(
                                fontSize: 14.5,
                                color: t.stone,
                                height: 1.55),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      isVoice
                          ? '${_time(m.createdAt)} · message vocal'
                          : _time(m.createdAt),
                      style: GwType.mono(
                          fontSize: 10,
                          color: t.stoneFaint,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sentBubble(GwTokens t, ChatMessageModel m) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.86),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: t.goldBg,
                border: Border.all(
                    color: GwTokens.gold.withValues(alpha: 0.3)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                m.content,
                style: GwType.ui(
                    fontSize: 14.5, color: t.stone, height: 1.55),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_time(m.createdAt)} · lu ✓✓',
              style: GwType.mono(
                  fontSize: 10, color: t.stoneFaint, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Forme d'onde du message vocal (statique — lecteur à venir).
  Widget _voiceContent(GwTokens t) {
    const heights = [8.0, 14.0, 10.0, 18.0, 12.0, 8.0, 15.0, 9.0, 13.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: t.goldBg, shape: BoxShape.circle),
          child: Icon(Symbols.play_arrow, size: 18, color: t.goldText),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < heights.length; i++)
              Container(
                width: 3,
                height: heights[i],
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: i < 5 ? t.goldText : t.stoneFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Text('0:42',
            style: GwType.mono(fontSize: 11, color: t.stoneDim)),
      ],
    );
  }

  /// Suggestion IA — pilule pointillée sage « Traduire en Bassa ».
  Widget _translatePill(GwTokens t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: GwTokens.sage.withValues(alpha: 0.4),
            radius: GwTokens.rBtn,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: GwTokens.sage.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.auto_awesome, size: 16, color: t.sageText),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Traduire cette conversation en Bassa ?',
                    style: GwType.ui(fontSize: 12.5, color: t.stoneMid),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _translateDismissed = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Traduction en Bassa — bientôt disponible',
                          style: GwType.ui(fontSize: 14, color: t.stone),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Activer',
                    style: GwType.ui(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: t.sageText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Barre de saisie — micro primaire ───────────────────────

  Widget _inputBar(GwTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Material(
            color: t.inkLift,
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              child: SizedBox(
                width: GwTokens.tapTarget,
                height: GwTokens.tapTarget,
                child: Icon(Symbols.add, size: 20, color: t.stoneMid),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _inputCtrl,
                style: GwType.ui(fontSize: 14, color: t.stone),
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Écrire au groupe…',
                  fillColor: t.inkCard,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GwTokens.rPill),
                    borderSide: BorderSide(color: t.lineMid),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GwTokens.rPill),
                    borderSide: BorderSide(color: t.lineMid),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GwTokens.rPill),
                    borderSide:
                        const BorderSide(color: GwTokens.gold, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Micro = action primaire (la voix des aînés) ; envoie si texte.
          Material(
            color: GwTokens.gold,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _hasText
                  ? _send
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Messages vocaux — bientôt disponibles',
                            style: GwType.ui(fontSize: 14, color: t.stone),
                          ),
                        ),
                      ),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  _hasText ? Symbols.send : Symbols.mic,
                  size: 20,
                  color: GwTokens.inkOnGold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    await ref
        .read(chatMessagesNotifierProvider(widget.groupId).notifier)
        .sendMessage(text);
  }

  // ── Helpers ────────────────────────────────────────────────

  Color _senderColor(GwTokens t, String senderId) {
    final palette = [t.sageText, t.azureText, t.emberText, t.goldText];
    return palette[senderId.hashCode.abs() % palette.length];
  }

  String _time(DateTime? dt) =>
      dt == null ? '' : DateFormat('HH:mm').format(dt);

  String _dayLabel(List<ChatMessageModel> messages) {
    final first = messages.isNotEmpty ? messages.first.createdAt : null;
    if (first == null) return "AUJOURD'HUI";
    final now = DateTime.now();
    if (first.year == now.year &&
        first.month == now.month &&
        first.day == now.day) {
      return "AUJOURD'HUI";
    }
    return DateFormat('d MMMM yyyy', 'fr').format(first).toUpperCase();
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  static const double _strokeWidth = 1;
  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color;
}
