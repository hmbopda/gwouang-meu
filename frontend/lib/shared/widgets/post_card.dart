import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/shared/models/post_model.dart';

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
  });

  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onVillageTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onLiveTap;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _liked = false;

  PostModel get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final isAi = post.isAiSuggestion;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAi
              ? Theme.of(context).colorScheme.primary.withAlpha(50)
              : Theme.of(context).colorScheme.outline.withAlpha(40),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi) _buildAiBanner(context),
          _buildHeader(context),
          _buildBody(context),
          if (post.postType == PostType.media) _buildMedia(context),
          if (post.postType == PostType.live) _buildLiveMedia(context),
          _buildStats(context),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withAlpha(15),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(30),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggestion Claude AI',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (post.aiDescription != null)
                  Text(
                    post.aiDescription!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
          if (post.aiConfidence != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withAlpha(50)),
              ),
              child: Text(
                'Confiance ${post.aiConfidence}',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onAuthorTap,
            child: _buildAvatar(42),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: widget.onAuthorTap,
                        child: Text(
                          post.authorDisplayName ?? 'Membre GWANG MEU',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    if (post.authorRole != null && post.authorRole != 'MEMBRE') ...[
                      const SizedBox(width: 6),
                      Builder(builder: (ctx) {
                        final accent = Theme.of(ctx).colorScheme.primary;
                        return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: accent.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          post.authorRole!,
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                      }),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (post.villageName != null)
                      GestureDetector(
                        onTap: widget.onVillageTap,
                        child: Text(
                          post.villageName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    if (post.createdAt != null) ...[
                      Text(
                        post.villageName != null ? ' · ' : '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        post.isLive ? 'En direct' : _formatDate(post.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                      ),
                    ],
                    if (post.isLive) ...[
                      const SizedBox(width: 6),
                      _liveBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz, size: 18),
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.content,
            style: post.isLargeText
                ? Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    )
                : Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: post.tags
                  .map((tag) => Text(
                        '#$tag',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    if (post.hasMediaGrid) return _buildMediaGrid();
    if (post.mediaUrl == null) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: post.mediaUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.surfaceAlt),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.surfaceAlt,
              child: const Center(
                child: Icon(Icons.image_outlined, size: 40, color: AppColors.textHint),
              ),
            ),
          ),
          if (post.mediaType == 'VIDEO')
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    final urls = post.mediaUrls;
    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: _gridCell(urls[0])),
          const SizedBox(width: 2),
          Expanded(child: _gridCell(urls[1])),
        ],
      );
    }
    return SizedBox(
      height: 240,
      child: Row(
        children: [
          Expanded(flex: 2, child: _gridCell(urls[0], height: 240)),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _gridCell(urls[1])),
                const SizedBox(height: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _gridCell(urls.length > 2 ? urls[2] : urls[1]),
                      if (urls.length > 3)
                        Container(
                          color: Colors.black.withAlpha(140),
                          child: Center(
                            child: Text(
                              '+${urls.length - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
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

  Widget _gridCell(String url, {double? height}) {
    return SizedBox(
      height: height,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(color: AppColors.surfaceAlt),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.surfaceAlt,
          child: const Icon(Icons.image_outlined, color: AppColors.textHint),
        ),
      ),
    );
  }

  Widget _buildLiveMedia(BuildContext context) {
    return GestureDetector(
      onTap: widget.onLiveTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.black.withAlpha(240), const Color(0xFF1A1A3A)],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, size: 52, color: Colors.white54),
                    const SizedBox(height: 12),
                    Text(
                      'Cliquez pour rejoindre le live',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _liveBadge(),
                      if (post.liveViewerCount != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${post.liveViewerCount} spectateurs',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    if (post.reactionCount == 0 && post.commentCount == 0 && post.shareCount == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(30)),
        ),
      ),
      child: Row(
        children: [
          if (post.reactionCount > 0) ...[
            if (post.reactions.isNotEmpty) _reactionStack() else Icon(Icons.favorite, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              '${post.reactionCount} reactions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
          const Spacer(),
          if (post.commentCount > 0)
            Text('${post.commentCount} commentaires', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
          if (post.shareCount > 0)
            Text(' · ${post.shareCount} partages', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _reactionStack() {
    final emojis = post.reactions.take(3).toList();
    return SizedBox(
      width: 14.0 * emojis.length + 6,
      height: 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < emojis.length; i++)
            Positioned(
              left: i * 10.0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(emojis[i], style: const TextStyle(fontSize: 10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (post.isAiSuggestion) return _buildAiActions(context);
    if (post.isLive) return _buildLiveActions(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(30))),
      ),
      child: Row(
        children: [
          _actionBtn(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            label: "J'aime",
            isActive: _liked,
            onTap: () {
              setState(() => _liked = !_liked);
              widget.onLike?.call();
            },
          ),
          _actionBtn(icon: Icons.chat_bubble_outline, label: 'Commenter', onTap: widget.onComment),
          _actionBtn(icon: Icons.share_outlined, label: 'Partager', onTap: widget.onShare),
        ],
      ),
    );
  }

  Widget _buildLiveActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(30))),
      ),
      child: Row(
        children: [
          _actionBtn(icon: Icons.play_arrow, label: 'Rejoindre le live', color: AppColors.error, onTap: widget.onLiveTap),
          _actionBtn(icon: Icons.notifications_outlined, label: 'Rappel', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildAiActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(30))),
      ),
      child: Row(
        children: [
          _actionBtn(icon: Icons.account_tree_outlined, label: "Voir l'arbre", color: Theme.of(context).colorScheme.primary, onTap: () {}),
          _actionBtn(icon: Icons.check_circle_outline, label: 'Confirmer', onTap: () {}),
          _actionBtn(icon: Icons.cancel_outlined, label: 'Rejeter', onTap: () {}),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    Color? color,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    final c = isActive ? Theme.of(context).colorScheme.primary : (color ?? AppColors.textSecondary);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    if (post.authorAvatarUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: CachedNetworkImageProvider(post.authorAvatarUrl!),
      );
    }
    final accent = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: accent.withAlpha(40),
      child: Text(
        (post.authorDisplayName ?? 'M').substring(0, 1).toUpperCase(),
        style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: size * 0.4),
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          SizedBox(width: 4),
          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('d MMM', 'fr').format(dt);
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

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
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}
