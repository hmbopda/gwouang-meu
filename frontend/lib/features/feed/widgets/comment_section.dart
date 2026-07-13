import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';

/// Un commentaire (avec bénédictions + réponses).
class FeedComment {
  FeedComment({
    required this.id,
    required this.content,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.parentCommentId,
    this.createdAt,
    this.reactionCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String content;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final String? parentCommentId;
  final DateTime? createdAt;
  int reactionCount; // mutable (optimiste)
  bool likedByMe; // mutable (optimiste)

  factory FeedComment.fromJson(Map<String, dynamic> j) => FeedComment(
        id: j['id']?.toString() ?? '',
        content: j['content'] as String? ?? '',
        authorDisplayName: j['authorDisplayName'] as String?,
        authorAvatarUrl: j['authorAvatarUrl'] as String?,
        parentCommentId: j['parentCommentId']?.toString(),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
        reactionCount: (j['reactionCount'] as num?)?.toInt() ?? 0,
        likedByMe: j['likedByMe'] as bool? ?? false,
      );
}

/// Section de commentaires EN LIGNE (façon Facebook) affichée sous une
/// publication : liste threadée + zone d'écriture. Bénir / répondre par
/// commentaire.
class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({super.key, required this.postId, this.onCommentAdded});

  final String postId;
  final VoidCallback? onCommentAdded;

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<FeedComment>? _comments;
  bool _loading = true;
  bool _sending = false;
  FeedComment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final json = await ref
          .read(apiClientProvider)
          .get('/api/v1/feed/${widget.postId}/comments');
      final data = json['data'];
      final list = data is List ? data : const [];
      if (!mounted) return;
      setState(() {
        _comments =
            list.map((e) => FeedComment.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final parentId = _replyingTo?.id;
    try {
      await ref.read(apiClientProvider).post(
        '/api/v1/feed/${widget.postId}/comments',
        data: {
          'content': text,
          if (parentId != null) 'parentCommentId': parentId,
        },
      );
      _ctrl.clear();
      if (parentId == null) widget.onCommentAdded?.call();
      if (mounted) setState(() => _replyingTo = null);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GwTokens.ember,
            content: Text("Le message n'a pas pu être envoyé",
                style: GwType.ui(fontSize: 14, color: GwTokens.inkOnGold)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleLike(FeedComment c) async {
    final wasLiked = c.likedByMe;
    setState(() {
      c.likedByMe = !wasLiked;
      c.reactionCount += wasLiked ? -1 : 1;
      if (c.reactionCount < 0) c.reactionCount = 0;
    });
    try {
      final client = ref.read(apiClientProvider);
      if (wasLiked) {
        await client.delete('/api/v1/feed/comments/${c.id}/react');
      } else {
        await client.post('/api/v1/feed/comments/${c.id}/react');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          c.likedByMe = wasLiked;
          c.reactionCount += wasLiked ? 1 : -1;
        });
      }
    }
  }

  void _startReply(FeedComment c) {
    setState(() => _replyingTo = c);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final all = _comments ?? const <FeedComment>[];
    final top = all.where((c) => c.parentCommentId == null).toList();
    final repliesByParent = <String, List<FeedComment>>{};
    for (final c in all) {
      if (c.parentCommentId != null) {
        (repliesByParent[c.parentCommentId!] ??= []).add(c);
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: t.goldText),
                ),
              ),
            )
          else if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Soyez le premier à répondre.',
                  style: GwType.ui(fontSize: 13, color: t.stoneDim)),
            )
          else
            for (final c in top) ...[
              _commentTile(t, c, isReply: false),
              for (final r in (repliesByParent[c.id] ?? const []))
                _commentTile(t, r, isReply: true),
            ],
          const SizedBox(height: 6),
          if (_replyingTo != null) _replyBanner(t),
          _inputBar(t),
        ],
      ),
    );
  }

  Widget _commentTile(GwTokens t, FeedComment c, {required bool isReply}) {
    final name = (c.authorDisplayName ?? '').trim();
    final displayName = name.isEmpty ? 'Membre' : name;
    final hasAvatar =
        c.authorAvatarUrl != null && c.authorAvatarUrl!.isNotEmpty;
    final r = isReply ? 14.0 : 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(isReply ? 34 : 0, 0, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: r,
            backgroundColor: t.goldBg,
            backgroundImage:
                hasAvatar ? NetworkImage(c.authorAvatarUrl!) : null,
            child: hasAvatar
                ? null
                : Text(displayName[0].toUpperCase(),
                    style: GwType.display(fontSize: 12, color: t.goldText)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.inkLift,
                    borderRadius: BorderRadius.circular(GwTokens.rCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: GwType.ui(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: t.stone)),
                      const SizedBox(height: 2),
                      Text(c.content,
                          style: GwType.ui(
                              fontSize: 13.5, color: t.stone, height: 1.45)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 3),
                  child: Row(
                    children: [
                      Text(_timeAgo(c.createdAt),
                          style:
                              GwType.mono(fontSize: 10, color: t.stoneFaint)),
                      const SizedBox(width: 14),
                      _miniAction(
                          c.likedByMe ? 'Aimé' : 'J’aime',
                          active: c.likedByMe,
                          color: c.likedByMe ? t.emberText : t.stoneMid,
                          onTap: () => _toggleLike(c)),
                      if (c.reactionCount > 0) ...[
                        const SizedBox(width: 4),
                        Text('${c.reactionCount}',
                            style: GwType.mono(
                                fontSize: 10.5, color: t.emberText)),
                      ],
                      const SizedBox(width: 14),
                      _miniAction('Répondre',
                          color: t.stoneMid,
                          onTap: () => _startReply(isReply
                              ? _parentOf(c) ?? c
                              : c)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  FeedComment? _parentOf(FeedComment reply) {
    final id = reply.parentCommentId;
    if (id == null) return null;
    for (final c in _comments ?? const <FeedComment>[]) {
      if (c.id == id) return c;
    }
    return null;
  }

  Widget _miniAction(String label,
      {required VoidCallback onTap, bool active = false, required Color color}) {
    return InkWell(
      onTap: onTap,
      child: Text(label,
          style: GwType.ui(
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: color)),
    );
  }

  Widget _replyBanner(GwTokens t) {
    final name = (_replyingTo?.authorDisplayName ?? 'ce message').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: GwTokens.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
      ),
      child: Row(
        children: [
          Icon(Symbols.reply, size: 15, color: t.goldText),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Réponse à $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GwType.ui(fontSize: 12.5, color: t.stoneMid)),
          ),
          InkWell(
            onTap: () => setState(() => _replyingTo = null),
            child: Icon(Symbols.close, size: 16, color: t.stoneMid),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(GwTokens t) {
    final user = ref.watch(profileNotifierProvider).valueOrNull;
    final name = (user?.displayName ?? '').trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarUrl = user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: t.goldBg,
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
          child: hasAvatar
              ? null
              : Text(initial,
                  style: GwType.display(fontSize: 12, color: t.goldText)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            style: GwType.ui(fontSize: 13.5, color: t.stone),
            decoration: InputDecoration(
              hintText: _replyingTo != null
                  ? 'Votre réponse…'
                  : 'Écrire un message…',
              hintStyle: GwType.ui(fontSize: 13, color: t.stoneDim),
              filled: true,
              fillColor: t.inkLift,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GwTokens.rPill),
                borderSide: BorderSide(color: t.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GwTokens.rPill),
                borderSide: BorderSide(color: t.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GwTokens.rPill),
                borderSide: const BorderSide(color: GwTokens.gold, width: 1.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: GwTokens.gold,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _sending ? null : _send,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: GwTokens.inkOnGold))
                  : const Icon(Symbols.send,
                      size: 17, color: GwTokens.inkOnGold),
            ),
          ),
        ),
      ],
    );
  }

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'maintenant';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    if (d.inDays < 7) return '${d.inDays} j';
    return '${(d.inDays / 7).floor()} sem';
  }
}
