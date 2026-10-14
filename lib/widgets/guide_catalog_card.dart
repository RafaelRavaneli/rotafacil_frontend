import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'profile_avatar.dart';

class GuideCatalogCard extends StatelessWidget {
  const GuideCatalogCard({
    super.key,
    required this.name,
    this.subtitle = '',
    this.photoUrl,
    this.verified = false,
    this.status,
    this.actions = const [],
  });
  final String name;
  final String subtitle;
  final String? photoUrl;
  final bool verified;
  final String? status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(dataUrl: photoUrl, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (verified) ...[
                      const SizedBox(height: 6),
                      const Wrap(
                        spacing: 5,
                        children: [
                          Icon(Icons.verified, size: 16, color: AppColors.leaf),
                          Text(
                            'Verificado',
                            style: TextStyle(
                              color: AppColors.forest,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 14),
            InvitationStatusChip(status: status!),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  if (index > 0) const SizedBox(height: 8),
                  actions[index],
                ],
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class InvitationStatusChip extends StatelessWidget {
  const InvitationStatusChip({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final label = switch (status.toLowerCase()) {
      'pendente' => 'Convite pendente',
      'aceito' => 'Convite aceito',
      'recusado' => 'Convite recusado',
      _ => status,
    };
    final color = status.toLowerCase() == 'recusado'
        ? AppColors.red
        : AppColors.forest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class GuideCollectionNotice extends StatelessWidget {
  const GuideCollectionNotice({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.forest,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
