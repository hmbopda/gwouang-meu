import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';

/// Un commentaire enrichi (renvoyé par GET /feed/{id}/comments).
class FeedComment {
  const FeedComment({
    required this.id,
    required this.content,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.createdAt,
  });

  final String id;
  final String content;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final DateTime? createdAt;

  factory FeedComment.fromJson(Map<String, dynamic> json) => FeedComment(
        id: json['id']?.toString() ?? '',
        content: json['content'] as String? ?? '',
        authorDisplayName: json['authorDisplayName'] as String?,
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
}

/// Ouvre la feuille de commentaires d'un post. [onAdded] est appelé après un
/// ajout réussi (pour incrémenter le compteur dans le fil).
Future<void> showCommentSheet(
  BuildContext context, {
  required String postId,
  VoidCallback? onAdded,
}) {
  return showGwDialog(
    context,
    builder: (_) => _CommentSheet(postId: postId, onAdded: onAdded),
  );
}

class _CommentSheet extends ConsumerStatefulWidget {
  const _CommentSheet({required this.postId, this.onAdded});

  final String postId;
  final VoidCallback? onAdded;

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  final _ctrl = TextEditingController();
  late Future<List<FeedComment>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<List<FeedComment>> _load() async {
    final client = ref.read(apiClientProvider);
    final json = await client.get('/api/v1/feed/${widget.postId}/comments');
    final data = json['data'];
    final list = data is List ? data : const [];
    return list
        .map((e) => FeedComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.post(
        '/api/v1/feed/${widget.postId}/comments',
        data: {'content': text},
      );
      _ctrl.clear();
      widget.onAdded?.call();
      setState(() => _future = _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GwTokens.ember,
            content: Text("Le commentaire n'a pas pu être envoyé",
                style: GwType.ui(fontSize: 14, color: GwTokens.inkOnGold)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return GwDialog(
      title: 'Commentaires',
      subtitle: 'Réagissez à cette publication',
      icon: Symbols.mode_comment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: FutureBuilder<List<FeedComment>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: t.goldText));
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Erreur de chargement',
                        style: GwType.ui(fontSize: 13, color: t.stoneDim)),
                  );
                }
                final comments = snap.data ?? const <FeedComment>[];
                if (comments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Aucun commentaire pour l’instant.\nSoyez le premier à réagir.',
                        textAlign: TextAlign.center,
                        style: GwType.ui(
                            fontSize: 13, color: t.stoneMid, height: 1.5),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _commentRow(t, comments[i]),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _inputBar(t),
        ],
      ),
    );
  }

  Widget _commentRow(GwTokens t, FeedComment c) {
    final name = (c.authorDisplayName ?? '').trim();
    final displayName = name.isEmpty ? 'Membre' : name;
    final hasAvatar =
        c.authorAvatarUrl != null && c.authorAvatarUrl!.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: t.goldBg,
          backgroundImage: hasAvatar ? NetworkImage(c.authorAvatarUrl!) : null,
          child: hasAvatar
              ? null
              : Text(displayName[0].toUpperCase(),
                  style: GwType.display(fontSize: 12, color: t.goldText)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: t.inkLift,
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: t.stone),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(c.createdAt),
                      style: GwType.mono(fontSize: 10, color: t.stoneFaint),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  c.content,
                  style:
                      GwType.ui(fontSize: 13.5, color: t.stone, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputBar(GwTokens t) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: InputDecoration(
              hintText: 'Écrire un commentaire…',
              hintStyle: GwType.ui(fontSize: 13.5, color: t.stoneDim),
              filled: true,
              fillColor: t.inkLift,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              width: 44,
              height: 44,
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: GwTokens.inkOnGold),
                    )
                  : const Icon(Symbols.send,
                      size: 19, color: GwTokens.inkOnGold),
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
