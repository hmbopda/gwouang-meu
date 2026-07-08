import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';

/// Overlay de chargement plein écran.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      color: t.ink.withAlpha(200),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: GwType.ui(fontSize: 14, color: t.stoneMid),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton shimmer pour une carte (village, post).
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 200});
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Shimmer.fromColors(
      baseColor: t.inkCard,
      highlightColor: t.inkLift,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: BorderRadius.circular(GwTokens.rCard),
        ),
      ),
    );
  }
}

/// Liste de skeletons shimmer.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.count = 5, this.cardHeight = 160});
  final int count;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => ShimmerCard(height: cardHeight),
    );
  }
}
