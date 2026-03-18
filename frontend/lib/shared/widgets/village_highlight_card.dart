import 'package:flutter/material.dart';

import '../models/village_model.dart';

class VillageHighlightCard extends StatelessWidget {
  const VillageHighlightCard({
    super.key,
    required this.village,
    this.onTap,
    this.onJoin,
  });

  final VillageModel village;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              accent.withAlpha(10),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: accent, width: 3),
            top: BorderSide(color: accent.withAlpha(20)),
            right: BorderSide(color: accent.withAlpha(20)),
            bottom: BorderSide(color: accent.withAlpha(20)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_city, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    village.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _metaChip(context, village.country),
                      const SizedBox(width: 8),
                      _metaChip(context, '${village.memberCount} membres'),
                      if (village.primaryDialect != null) ...[
                        const SizedBox(width: 8),
                        _metaChip(context, village.primaryDialect!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onJoin,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+ Rejoindre',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
    );
  }
}
