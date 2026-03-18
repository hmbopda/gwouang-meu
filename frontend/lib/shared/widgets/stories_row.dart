import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StoryData {
  final String id;
  final String name;
  final String? villageName;
  final String? avatarUrl;
  final String? backgroundUrl;
  final Color? backgroundGradientStart;
  final Color? backgroundGradientEnd;
  final bool isLiveReplay;

  const StoryData({
    required this.id,
    required this.name,
    this.villageName,
    this.avatarUrl,
    this.backgroundUrl,
    this.backgroundGradientStart,
    this.backgroundGradientEnd,
    this.isLiveReplay = false,
  });
}

class StoriesRow extends StatelessWidget {
  const StoriesRow({
    super.key,
    required this.stories,
    this.onStoryTap,
    this.onAddStory,
  });

  final List<StoryData> stories;
  final void Function(StoryData)? onStoryTap;
  final VoidCallback? onAddStory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) return _AddStoryCard(onTap: onAddStory);
          return _StoryCard(
            story: stories[index - 1],
            onTap: () => onStoryTap?.call(stories[index - 1]),
          );
        },
      ),
    );
  }
}

class _AddStoryCard extends StatelessWidget {
  const _AddStoryCard({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(30),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(builder: (ctx) {
              final accent = Theme.of(ctx).colorScheme.primary;
              return Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: accent, size: 22),
            );
            }),
            const SizedBox(height: 8),
            Text(
              'Ajouter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, this.onTap});
  final StoryData story;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            if (story.backgroundUrl != null)
              CachedNetworkImage(
                imageUrl: story.backgroundUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _gradientBg(),
              )
            else
              _gradientBg(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(50),
                    Colors.black.withAlpha(180),
                  ],
                ),
              ),
            ),

            // Avatar
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.5),
                  ),
                  child: ClipOval(
                    child: story.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: story.avatarUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _avatarFallback(context),
                          )
                        : _avatarFallback(context),
                  ),
                ),
              ),
            ),

            // Village name
            if (story.villageName != null)
              Positioned(
                bottom: 26,
                left: 0,
                right: 0,
                child: Text(
                  story.villageName!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),

            // Name
            Positioned(
              bottom: 10,
              left: 6,
              right: 6,
              child: Text(
                story.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Live replay badge
            if (story.isLiveReplay)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'REPLAY',
                    style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            story.backgroundGradientStart ?? const Color(0xFF1A3300),
            story.backgroundGradientEnd ?? const Color(0xFF4A8800),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      alignment: Alignment.center,
      child: Text(
        story.name.isNotEmpty ? story.name[0].toUpperCase() : '?',
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}
