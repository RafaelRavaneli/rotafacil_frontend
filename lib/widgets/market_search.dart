import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MarketSearch extends StatelessWidget {
  const MarketSearch({
    super.key,
    required this.onTap,
    this.hint = 'Cidade, dificuldade ou data',
  });

  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      elevation: 5,
      shadowColor: AppColors.shadow,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.ink, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Para onde?',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.green700,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
