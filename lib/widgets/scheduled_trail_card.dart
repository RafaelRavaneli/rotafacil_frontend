import 'package:flutter/material.dart';

import '../models/trail.dart';
import '../theme/app_colors.dart';
import '../utils/date_time_format.dart';
import 'network_image_box.dart';

class ScheduledTrailCard extends StatelessWidget {
  const ScheduledTrailCard({
    super.key,
    required this.trail,
    required this.departure,
    this.onParticipants,
    this.onEdit,
    this.onDeactivate,
  });

  final Trail trail;
  final TrailDeparture departure;
  final VoidCallback? onParticipants;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final hasActions =
        onParticipants != null || onEdit != null || onDeactivate != null;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 86,
              height: 86,
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
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    trail.location,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatBrazilianDateTime(departure.startsAt),
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (hasActions)
              PopupMenuButton<String>(
                tooltip: 'Ações do roteiro',
                onSelected: (value) {
                  switch (value) {
                    case 'participants':
                      onParticipants?.call();
                    case 'edit':
                      onEdit?.call();
                    case 'deactivate':
                      onDeactivate?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (onParticipants != null)
                    const PopupMenuItem(
                      value: 'participants',
                      child: Text('Ver inscritos'),
                    ),
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (onDeactivate != null)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Text('Desativar'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
