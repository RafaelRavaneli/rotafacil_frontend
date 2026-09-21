import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MarketSearch extends StatelessWidget {
  const MarketSearch({
    super.key,
    required this.onTap,
    this.hint = 'Buscar trilhas, destinos...',
  });

  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      elevation: 2,
      shadowColor: AppColors.shadow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.ink,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.tune_rounded,
                color: AppColors.green700,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
