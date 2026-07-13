import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/models/post_model.dart';

/// Carte du Fil de famille — chaleureuse (thème crème), inspirée de la maquette
/// « Fil de famille ». Deux visages : publication normale (souvenir, photo) et
/// événement d'arbre (naissance/union, contenu préfixé 🌳/💍) avec « Voir dans
/// l'arbre ». Actions : bénédictions · messages · partager.
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onOpenTree,
  });

  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onOpenTree;

  bool get _isTreeEvent {
    final c = post.content.trimLeft();
    return c.startsWith('🌳') || c.startsWith('💍');
  }

  bool get _isUnion => post.content.trimLeft().startsWith('💍');
  bool get _isVillage =>
      post.villageId != null && post.villageId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final name = (post.authorDisplayName ?? '').trim();
    final displayName = name.isEmpty ? 'Un membre' : name;
    final hasMedia = post.mediaUrl != null && post.mediaUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        border: Border.all(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(t, displayName),
            const SizedBox(height: 12),
            if (_isTreeEvent)
              _eventBody(t)
            else ...[
              if (post.content.trim().isNotEmpty)
                Text(post.content,
                    style: GwType.ui(
                        fontSize: 15, color: t.stone, height: 1.55)),
              if (hasMedia) ...[
                const SizedBox(height: 12),
                _media(t),
              ],
            ],
            const SizedBox(height: 12),
            _footer(t),
          ],
        ),
      ),
    );
  }

  Widget _header(GwTokens t, String displayName) {
    final avatarUrl = post.authorAvatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final accent = _isTreeEvent ? GwTokens.sage : GwTokens.gold;
    final scope = _isTreeEvent
        ? (_isUnion ? 'ÉVÉNEMENT · UNION' : 'ÉVÉNEMENT · LIGNÉE')
        : (_isVillage
            ? (post.villageName ?? 'VILLAGE').toUpperCase()
            : 'PUBLICATION');
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: accent.withValues(alpha: 0.18),
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
          child: hasAvatar
              ? null
              : Text(displayName[0].toUpperCase(),
                  style: GwType.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _isTreeEvent ? t.sageText : t.goldText)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.ui(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: t.stone)),
              const SizedBox(height: 2),
              Text('$scope · ${_timeAgo(post.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.mono(
                      fontSize: 10.5,
                      color: _isTreeEvent ? t.sageText : t.stoneFaint,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
      ],
    );
  }

  /// Corps d'un événement d'arbre : encart teinté + « Voir dans l'arbre ».
  Widget _eventBody(GwTokens t) {
    final content = post.content.trimLeft();
    // Retire l'émoji de tête pour l'afficher comme icône dédiée.
    final text = content.replaceFirst(RegExp(r'^(🌳|💍)\s*'), '');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GwTokens.sage.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: GwTokens.sage.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: GwTokens.sage.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                    _isUnion ? Symbols.favorite : Symbols.psychiatry,
                    size: 19,
                    color: t.sageText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: GwType.ui(
                        fontSize: 14.5, color: t.stone, height: 1.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: GwTokens.sage,
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              child: InkWell(
                onTap: onOpenTree,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.account_tree,
                          size: 16, color: Color(0xFFF0EBE1)),
                      const SizedBox(width: 7),
                      Text('Voir dans l’arbre',
                          style: GwType.ui(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF0EBE1))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
                      strokeWidth: 2, color: t.goldText)),
          errorBuilder: (ctx, _, __) => Container(
            color: t.inkLift,
            alignment: Alignment.center,
            child:
                Icon(Symbols.broken_image, size: 32, color: t.stoneFaint),
          ),
        ),
      ),
    );
  }

  Widget _footer(GwTokens t) {
    return Column(
      children: [
        if (post.reactionCount > 0 || post.commentCount > 0) ...[
          Row(
            children: [
              if (post.reactionCount > 0) ...[
                Icon(Symbols.favorite, size: 13, color: t.emberText, fill: 1),
                const SizedBox(width: 4),
                Text(
                    '${post.reactionCount} bénédiction${post.reactionCount > 1 ? 's' : ''}',
                    style: GwType.mono(fontSize: 11.5, color: t.stoneMid)),
              ],
              if (post.reactionCount > 0 && post.commentCount > 0)
                const SizedBox(width: 14),
              if (post.commentCount > 0)
                Text(
                    '${post.commentCount} message${post.commentCount > 1 ? 's' : ''}',
                    style: GwType.mono(fontSize: 11.5, color: t.stoneMid)),
            ],
          ),
          Divider(height: 16, color: t.line),
        ],
        Row(
          children: [
            _actionBtn(t,
                icon: post.likedByMe
                    ? Symbols.favorite
                    : Symbols.favorite_border,
                label: 'Bénir',
                active: post.likedByMe,
                activeColor: t.emberText,
                onTap: onLike),
            _actionBtn(t,
                icon: Symbols.mode_comment,
                label: 'Message',
                onTap: onComment),
            _actionBtn(t,
                icon: Symbols.ios_share, label: 'Partager', onTap: onShare),
          ],
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
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(
                        fontSize: 13,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return "à l'instant";
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays < 7) return 'il y a ${d.inDays} j';
    if (d.inDays < 30) return 'il y a ${(d.inDays / 7).floor()} sem';
    if (d.inDays < 365) return 'il y a ${(d.inDays / 30).floor()} mois';
    return 'il y a ${(d.inDays / 365).floor()} an${d.inDays >= 730 ? 's' : ''}';
  }
}
