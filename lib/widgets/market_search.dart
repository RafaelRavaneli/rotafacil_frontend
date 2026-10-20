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
      color: AppColors.forest,
      elevation: 8,
      shadowColor: AppColors.forest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Encontre seu próximo roteiro',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Busque por destino, atividade, data ou dificuldade.',
                style: TextStyle(color: AppColors.sage, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.forest,
                      size: 27,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buscar roteiros',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
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
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.green100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.forest,
                        size: 21,
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
