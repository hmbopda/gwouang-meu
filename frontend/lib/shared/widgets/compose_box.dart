import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ComposeBox extends StatelessWidget {
  const ComposeBox({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.onTap,
    this.onLiveTap,
    this.onPhotoTap,
    this.onVillageTap,
  });

  final String? avatarUrl;
  final String? displayName;
  final VoidCallback? onTap;
  final VoidCallback? onLiveTap;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onVillageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(40),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Top row: avatar + input
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                _buildAvatar(context),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(60),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withAlpha(30),
                        ),
                      ),
                      child: Text(
                        'Quoi de neuf dans votre village ?',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withAlpha(30),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                _composeAction(
                  context,
                  icon: Icons.videocam_outlined,
                  label: 'Live video',
                  color: AppColors.error,
                  onTap: onLiveTap,
                ),
                _composeAction(
                  context,
                  icon: Icons.photo_outlined,
                  label: 'Photo',
                  color: AppColors.success,
                  onTap: onPhotoTap,
                ),
                _composeAction(
                  context,
                  icon: Icons.location_city_outlined,
                  label: 'Village',
                  color: AppColors.info,
                  onTap: onVillageTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
      );
    }
    final accent = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: 20,
      backgroundColor: accent.withAlpha(40),
      child: Text(
        (displayName ?? 'M').substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _composeAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
