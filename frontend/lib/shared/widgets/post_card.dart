import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/models/post_model.dart';

/// PostCard « Tissage » — gabarits différenciés par type de post :
/// - **citation** (`isLargeText`) : barre tissée verticale 5 px + Fraunces
///   italique 19 px + grand guillemet or
/// - **média** : image full-bleed avec auteur en overlay
/// - **encart IA** : fond sage 8-14 %, bordure sage 35 %, label mono
///   « MÉMOIRE FAMILIALE · CONFIANCE X% », CTA sage + bouton fermer
/// - **live** : zone immersive + badge ember
/// - **texte** : gabarit simple
/// Actions en pilules (inkLift, 8×14, cœur ember).
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onVillageTap,
    this.onAuthorTap,
    this.onLiveTap,
    this.onAiExplore,
    this.onAiDismiss,
  });

  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onVillageTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onLiveTap;

  /// Encart IA : « Explorer le lien ».
  final VoidCallback? onAiExplore;

  /// Encart IA : rejeter la suggestion.
  final VoidCallback? onAiDismiss;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _liked = false;

  PostModel get post => widget.post;

  @override
  Widget build(BuildContext context) {
    switch (post.postType) {
      case PostType.aiSuggestion:
        return _AiMemoryCard(
          post: post,
          onExplore: widget.onAiExplore,
          onDismiss: widget.onAiDismiss,
        );
      case PostType.media:
        return _buildMediaPost(context);
      case PostType.live:
        return _buildLivePost(context);
      case PostType.text:
        return post.isLargeText
            ? _buildQuotePost(context)
            : _buildTextPost(context);
    }
  }

  // ───────────────────────────────────────────────────────────────
  //  Gabarit CITATION — barre tissée + Fraunces italique
  // ───────────────────────────────────────────────────────────────

  Widget _buildQuotePost(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GwWeaveBarVertical(width: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(19, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“',
                      style: GwType.display(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: GwTokens.gold.withValues(alpha: 0.35),
                        height: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.content,
                      style: GwType.quote(fontSize: 19, color: t.stone, height: 1.55),
                    ),
                    const SizedBox(height: 16),
                    _authorRow(context, withActions: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  Gabarit MÉDIA — image full-bleed, auteur en overlay
  // ───────────────────────────────────────────────────────────────

  Widget _buildMediaPost(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _media(context),
              Positioned(
                left: 16,
                bottom: 14,
                child: Row(
                  children: [
                    _initialAvatar(
                      post.authorDisplayName,
                      size: 32,
                      bg: GwTokens.emberBg,
                      fg: t.emberText,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      [
                        post.authorDisplayName ?? 'Membre',
                        if (post.villageName != null) post.villageName!,
                      ].join(' · '),
                      style: GwType.ui(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ).copyWith(shadows: [
                        const Shadow(
                            blurRadius: 6,
                            color: Color(0xB3000000),
                            offset: Offset(0, 1)),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.content,
                  style: GwType.ui(fontSize: 15, color: t.stone, height: 1.65),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _pillAction(
                      context,
                      icon: Symbols.favorite,
                      fill: _liked ? 1 : 0,
                      iconColor: t.emberText,
                      label: '${post.reactionCount}',
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 10),
                    _pillAction(
                      context,
                      icon: Symbols.chat_bubble,
                      iconColor: t.stoneMid,
                      label: '${post.commentCount}',
                      onTap: widget.onComment,
                    ),
                    const Spacer(),
                    if (post.tags.isNotEmpty)
                      Text(
                        '#${post.tags.first}',
                        style: GwType.mono(
                            fontSize: 11, color: t.goldText, letterSpacing: 0.5),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _media(BuildContext context) {
    final t = GwTokens.of(context);
    final placeholder = Container(
      height: 200,
      width: double.infinity,
      color: t.inkLift,
      alignment: Alignment.center,
      child: Icon(Symbols.image, size: 40, color: t.stoneDim),
    );
    if (post.mediaUrl == null) return placeholder;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: post.mediaUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: t.inkLift),
            errorWidget: (_, __, ___) => placeholder,
          ),
          if (post.mediaType == 'VIDEO')
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Symbols.play_arrow, color: Colors.white, size: 32),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  Gabarit LIVE
  // ───────────────────────────────────────────────────────────────

  Widget _buildLivePost(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        border: Border.all(color: GwTokens.emberLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                _liveBadge(),
                const SizedBox(width: 10),
                if (post.liveViewerCount != null)
                  Text(
                    '${post.liveViewerCount} À L\'ÉCOUTE',
                    style: GwType.mono(fontSize: 10, color: t.stoneFaint),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.content,
                  style: GwType.ui(fontSize: 15, color: t.stone, height: 1.6),
                ),
                const SizedBox(height: 14),
                _authorRow(context),
                const SizedBox(height: 14),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onLiveTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: GwTokens.ember,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(GwTokens.rBtn),
                      ),
                    ),
                    icon: const Icon(Symbols.play_arrow, size: 18),
                    label: Text(
                      'Rejoindre le live',
                      style:
                          GwType.ui(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  Gabarit TEXTE simple
  // ───────────────────────────────────────────────────────────────

  Widget _buildTextPost(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _authorRow(context),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: GwType.ui(fontSize: 15, color: t.stone, height: 1.65),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pillAction(
                context,
                icon: Symbols.favorite,
                fill: _liked ? 1 : 0,
                iconColor: t.emberText,
                label: '${post.reactionCount}',
                onTap: _toggleLike,
              ),
              const SizedBox(width: 10),
              _pillAction(
                context,
                icon: Symbols.chat_bubble,
                iconColor: t.stoneMid,
                label: '${post.commentCount}',
                onTap: widget.onComment,
              ),
              const Spacer(),
              if (post.tags.isNotEmpty)
                Text(
                  '#${post.tags.first}',
                  style: GwType.mono(
                      fontSize: 11, color: t.goldText, letterSpacing: 0.5),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  Éléments partagés
  // ───────────────────────────────────────────────────────────────

  void _toggleLike() {
    setState(() => _liked = !_liked);
    widget.onLike?.call();
  }

  Widget _authorRow(BuildContext context, {bool withActions = false}) {
    final t = GwTokens.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onAuthorTap,
          child: _initialAvatar(
            post.authorDisplayName,
            size: 36,
            bg: t.goldBg,
            fg: t.goldText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorDisplayName ?? 'Membre GWANG MEU',
                style: GwType.ui(
                    fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                [
                  if (post.villageName != null) post.villageName!,
                  if (post.createdAt != null) _formatDate(post.createdAt!),
                ].join(' · '),
                style: GwType.ui(fontSize: 12, color: t.stoneFaint),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (withActions) ...[
          _pillAction(
            context,
            icon: Symbols.favorite,
            fill: _liked ? 1 : 0,
            iconColor: t.emberText,
            label: '${post.reactionCount}',
            onTap: _toggleLike,
          ),
          const SizedBox(width: 8),
          _pillAction(
            context,
            icon: Symbols.chat_bubble,
            iconColor: t.stoneMid,
            label: '${post.commentCount}',
            onTap: widget.onComment,
          ),
        ],
      ],
    );
  }

  /// Pilule d'action (inkLift, rayon 99, padding 8×14).
  Widget _pillAction(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    double fill = 0,
    VoidCallback? onTap,
  }) {
    final t = GwTokens.of(context);
    return Material(
      color: t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor, fill: fill),
              const SizedBox(width: 6),
              Text(
                label,
                style: GwType.ui(
                    fontSize: 13, fontWeight: FontWeight.w600, color: t.stone),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialAvatar(String? name,
      {required double size, required Color bg, required Color fg}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        (name ?? 'M').substring(0, 1).toUpperCase(),
        style: GwType.display(
            fontSize: size * 0.4, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _liveBadge() {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: GwTokens.emberBg,
        border: Border.all(color: GwTokens.emberLine),
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(),
          const SizedBox(width: 6),
          Text(
            'EN DIRECT',
            style: GwType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: t.emberText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return DateFormat('d MMM', 'fr').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────
//  Encart IA « Mémoire familiale » — narratif, pulse doux 2,4 s
// ─────────────────────────────────────────────────────────────────

class _AiMemoryCard extends StatefulWidget {
  const _AiMemoryCard({required this.post, this.onExplore, this.onDismiss});

  final PostModel post;
  final VoidCallback? onExplore;
  final VoidCallback? onDismiss;

  @override
  State<_AiMemoryCard> createState() => _AiMemoryCardState();
}

class _AiMemoryCardState extends State<_AiMemoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final confidence = widget.post.aiConfidence ?? '—';

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.10 + 0.10 * _pulse.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GwTokens.sage.withValues(alpha: 0.14),
                GwTokens.sage.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(GwTokens.rCardLg),
            border: Border.all(color: GwTokens.sage.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: GwTokens.sage.withValues(alpha: glow),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.auto_awesome, size: 20, color: t.sageText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'MÉMOIRE FAMILIALE · CONFIANCE ${confidence.toUpperCase()}',
                  style: GwType.mono(
                      fontSize: 10, color: t.sageText, letterSpacing: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.post.content,
            style: GwType.ui(fontSize: 15, color: t.stone, height: 1.65),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: widget.onExplore,
                    style: FilledButton.styleFrom(
                      backgroundColor: GwTokens.sage,
                      foregroundColor: const Color(0xFFF0EBE1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(GwTokens.rBtn),
                      ),
                    ),
                    icon: const Icon(Symbols.account_tree, size: 18),
                    label: Text(
                      'Explorer le lien',
                      style:
                          GwType.ui(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: t.inkLift,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                child: InkWell(
                  onTap: widget.onDismiss,
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Symbols.close, size: 20, color: t.stoneFaint),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_ctrl),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
            color: GwTokens.of(context).emberText, shape: BoxShape.circle),
      ),
    );
  }
}
