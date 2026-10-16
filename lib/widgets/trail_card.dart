import 'package:flutter/material.dart';

import '../models/trail.dart';
import '../theme/app_colors.dart';
import 'network_image_box.dart';

class TrailCard extends StatelessWidget {
  const TrailCard({
    super.key,
    required this.trail,
    required this.onTap,
    required this.favorite,
    required this.onFavorite,
  });

  final Trail trail;
  final VoidCallback onTap;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkImageBox(url: trail.imageUrl, borderRadius: 20),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trail.difficulty,
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Material(
                      color: AppColors.paper.withValues(alpha: .94),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: favorite
                            ? 'Remover dos favoritos'
                            : 'Adicionar aos favoritos',
                        onPressed: onFavorite,
                        icon: Icon(
                          favorite ? Icons.favorite : Icons.favorite_border,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    trail.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (trail.rating > 0) ...[
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.earth,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    trail.rating.toStringAsFixed(1).replaceAll('.', ','),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              trail.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              [
                trail.distanceLabel,
                if (trail.date.isNotEmpty) trail.date,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 7),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        'R\$ ${trail.price.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const TextSpan(text: ' por pessoa'),
                ],
              ),
              style: const TextStyle(color: AppColors.ink, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
