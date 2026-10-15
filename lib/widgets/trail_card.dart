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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                height: 154,
                child: NetworkImageBox(url: trail.imageUrl, borderRadius: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trail.name,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      trail.location,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${trail.difficulty} · ${trail.distanceLabel}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (trail.date.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        trail.date,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'R\$ ${trail.price.toStringAsFixed(2).replaceAll('.', ',')} por pessoa',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
