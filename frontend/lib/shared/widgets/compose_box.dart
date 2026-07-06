import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';

/// Compose « Tissage » — une seule ligne chaleureuse :
/// avatar or + invite Fraunces italique + icône éditer.
class ComposeBox extends StatelessWidget {
  const ComposeBox({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.onTap,
  });

  final String? avatarUrl;
  final String? displayName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final firstName = (displayName ?? '').trim().split(' ').first;
    final prompt = firstName.isEmpty
        ? 'Quelle nouvelle du village ?'
        : 'Quelle nouvelle du village, $firstName ?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: t.inkLift,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GwTokens.rCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _avatar(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    prompt,
                    style: GwType.quote(fontSize: 14, color: t.stoneFaint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Symbols.edit, size: 22, color: t.goldText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration:
          const BoxDecoration(color: GwTokens.gold, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        (displayName ?? 'M').substring(0, 1).toUpperCase(),
        style: GwType.display(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0C0B0F),
        ),
      ),
    );
  }
}
