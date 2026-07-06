import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';

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

/// Stories « Tissage » — tuiles 72 px carrées arrondies (24 px) avec anneau
/// dégradé or/ember/sage, initiale Fraunces, tuile « Raconter » en pointillé or.
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
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: stories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) return _AddStoryTile(onTap: onAddStory);
          return _StoryTile(
            story: stories[index - 1],
            onTap: () => onStoryTap?.call(stories[index - 1]),
          );
        },
      ),
    );
  }
}

class _AddStoryTile extends StatelessWidget {
  const _AddStoryTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            CustomPaint(
              foregroundPainter: _DashedRRectPainter(
                color: GwTokens.gold.withValues(alpha: 0.5),
                radius: 24,
                strokeWidth: 1.5,
              ),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: t.inkLift,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Symbols.add, size: 26, color: t.goldText),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Raconter',
              style: GwType.ui(fontSize: 12, color: t.stoneMid),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.story, this.onTap});

  final StoryData story;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            // Anneau dégradé tissé or → ember → sage
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [GwTokens.gold, GwTokens.ember, GwTokens.sage],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: t.ink, width: 2),
                  gradient: story.backgroundUrl == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            story.backgroundGradientStart ?? t.inkLift,
                            story.backgroundGradientEnd ?? t.inkHigh,
                          ],
                        )
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: story.backgroundUrl != null
                    ? CachedNetworkImage(
                        imageUrl: story.backgroundUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Text(
                        story.name.substring(0, 1).toUpperCase(),
                        style: GwType.display(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF0EBE1),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.name,
              style: GwType.ui(
                  fontSize: 12, fontWeight: FontWeight.w500, color: t.stone),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordure pointillée arrondie (tuile « Raconter »).
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dash = 5,
    this.gap = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
