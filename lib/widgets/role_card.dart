import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../theme/app_colors.dart';

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.role,
    required this.onTap,
  });

  final UserRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = switch (role) {
      UserRole.tourist => (
          Icons.hiking_rounded,
          'Quero descobrir trilhas e viver novas aventuras.'
        ),
      UserRole.guide => (
          Icons.flag_rounded,
          'Quero compartilhar meu conhecimento e guiar aventureiros.'
        ),
      UserRole.agency => (
          Icons.apartment_rounded,
          'Represento uma agência e organizo experiências para grupos.'
        ),
    };

    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  data.$1,
                  color: AppColors.green800,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.title,
                      style: const TextStyle(
                        color: AppColors.green900,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.$2,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.green900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
