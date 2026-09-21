import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.compact = true,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();

    Color bg = AppColors.green100;
    Color fg = AppColors.green800;

    if (normalized.contains('pendente') ||
        normalized.contains('revis')) {
      bg = AppColors.amber100;
      fg = AppColors.amber700;
    }

    if (normalized.contains('cancel')) {
      bg = const Color(0xFFFFE6E3);
      fg = AppColors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: compact ? 10.5 : 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
