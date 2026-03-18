import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_theme.dart';
import '../models/village_model.dart';

/// Carte village réutilisable — liste, grille, recherche.
class VillageCard extends StatelessWidget {
  const VillageCard({super.key, required this.village});

  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.villageDetail(village.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de couverture
            AspectRatio(
              aspectRatio: 16 / 9,
              child: village.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: village.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _shimmer(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + badge vérifié
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          village.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (village.verified)
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Pays + dialecte
                  Text(
                    [village.country, village.primaryDialect]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Membres
                  Row(
                    children: [
                      const Icon(Icons.group_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${village.memberCount} membres',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceAlt,
        child: const Center(
          child: Icon(Icons.landscape_outlined, size: 32, color: AppColors.textHint),
        ),
      );

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.surfaceAlt,
        child: Container(color: AppColors.surface),
      );
}
