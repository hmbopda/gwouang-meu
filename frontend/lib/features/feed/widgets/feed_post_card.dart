import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/models/post_model.dart';

/// Carte de publication du fil « Tissage » — inspirée Facebook/Instagram mais
/// dans l'identité maison : bande tissée d'accent selon la portée (village = or,
/// personnel = azur), en-tête auteur, contenu, média, compteurs et barre
/// d'actions (J'aime / Commenter / Partager).
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  bool get _isVillage => post.villageId != null && post.villageId!.isNotEmpty;

  Color _accent() => _isVillage ? GwTokens.gold : GwTokens.azure;

  String _scopeLabel() {
    if (_isVillage) {
      final n = post.villageName;
      return (n != null && n.isNotEmpty) ? n : 'Village';
    }
    return 'Publication';
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final accent = _accent();
    final name = (post.authorDisplayName ?? '').trim();
    final displayName = name.isEmpty ? 'Membre' : name;
    final hasMedia = post.mediaUrl != null && post.mediaUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        border: Border.all(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bande d'accent verticale = portée de la publication
          Container(width: 4, color: accent.withValues(alpha: 0.85)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(t, accent, displayName),
                  const SizedBox(height: 10),
                  if (post.content.trim().isNotEmpty)
                    Text(
                      post.content,
                      style: GwType.ui(
                          fontSize: 15, color: t.stone, height: 1.55),
                    ),
                  if (hasMedia) ...[
                    const SizedBox(height: 12),
                    _media(t),
                  ],
                  const SizedBox(height: 12),
                  _counts(t, accent),
                  Divider(height: 18, color: t.line),
                  _actions(t, accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(GwTokens t, Color accent, String displayName) {
    final avatarUrl = post.authorAvatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final initial = displayName[0].toUpperCase();
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: accent.withValues(alpha: 0.18),
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
          child: hasAvatar
              ? null
              : Text(initial,
                  style: GwType.display(
                      fontSize: 16, fontWeight: FontWeight.w700, color: accent)),
        ),
        const SizedBox(width: 11),
        Expanded(
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: t.stone),
                    ),
                  ),
                  if (_roleLabel() != null) ...[
                    const SizedBox(width: 6),
                    _roleChip(t, accent),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(_isVillage ? Symbols.holiday_village : Symbols.public,
                      size: 12, color: accent),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${_scopeLabel()} · ${_timeAgo(post.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.mono(
                          fontSize: 11, color: t.stoneFaint, letterSpacing: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _roleLabel() {
    switch (post.authorRole) {
      case 'SUPER_ADMIN':
        return 'ADMIN';
      case 'MODERATEUR':
        return 'MODÉRATEUR';
      case 'AMBASSADEUR':
        return 'AMBASSADEUR';
      default:
        return null;
    }
  }

  Widget _roleChip(GwTokens t, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
      child: Text(
        _roleLabel()!,
        style: GwType.mono(
            fontSize: 8.5, letterSpacing: 0.8, color: accent),
      ),
    );
  }

  Widget _media(GwTokens t) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.network(
          post.mediaUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) => progress == null
              ? child
              : Container(
                  color: t.inkLift,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: t.goldText),
                ),
          errorBuilder: (ctx, _, __) => Container(
            color: t.inkLift,
            alignment: Alignment.center,
            child: Icon(Symbols.broken_image, size: 32, color: t.stoneFaint),
          ),
        ),
      ),
    );
  }

  Widget _counts(GwTokens t, Color accent) {
    if (post.reactionCount == 0 && post.commentCount == 0) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (post.reactionCount > 0) ...[
          Icon(Symbols.favorite, size: 13, color: accent, fill: 1),
          const SizedBox(width: 4),
          Text('${post.reactionCount}',
              style: GwType.mono(fontSize: 12, color: t.stoneMid)),
        ],
        if (post.reactionCount > 0 && post.commentCount > 0)
          const SizedBox(width: 14),
        if (post.commentCount > 0)
          Text(
            '${post.commentCount} commentaire${post.commentCount > 1 ? 's' : ''}',
            style: GwType.mono(fontSize: 12, color: t.stoneMid),
          ),
      ],
    );
  }

  Widget _actions(GwTokens t, Color accent) {
    return Row(
      children: [
        _actionBtn(
          t,
          icon: post.likedByMe ? Symbols.favorite : Symbols.favorite_border,
          label: 'J’aime',
          active: post.likedByMe,
          activeColor: GwTokens.ember,
          onTap: onLike,
        ),
        _actionBtn(
          t,
          icon: Symbols.mode_comment,
          label: 'Commenter',
          onTap: onComment,
        ),
        _actionBtn(
          t,
          icon: Symbols.ios_share,
          label: 'Partager',
          onTap: onShare,
        ),
      ],
    );
  }

  Widget _actionBtn(
    GwTokens t, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    Color? activeColor,
  }) {
    final color = active ? (activeColor ?? t.goldText) : t.stoneMid;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: color, fill: active ? 1 : 0),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.ui(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final d = now.difference(dt);
    if (d.inSeconds < 60) return "à l'instant";
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays < 7) return 'il y a ${d.inDays} j';
    if (d.inDays < 30) return 'il y a ${(d.inDays / 7).floor()} sem';
    if (d.inDays < 365) return 'il y a ${(d.inDays / 30).floor()} mois';
    return 'il y a ${(d.inDays / 365).floor()} an${d.inDays >= 730 ? 's' : ''}';
  }
}
