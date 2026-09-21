import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.large = false,
    this.showName = true,
    this.light = false,
  });

  final bool large;
  final bool showName;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final size = large ? 88.0 : 36.0;
    final color = light ? AppColors.white : AppColors.green900;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light
                ? AppColors.white.withValues(alpha: .12)
                : AppColors.green100,
            shape: BoxShape.circle,
            border: Border.all(
              color: light
                  ? AppColors.white.withValues(alpha: .35)
                  : AppColors.green700.withValues(alpha: .18),
            ),
          ),
          child: Icon(
            Icons.landscape_rounded,
            size: large ? 50 : 22,
            color: color,
          ),
        ),
        if (showName) ...[
          SizedBox(width: large ? 0 : 8),
          if (!large)
            Text(
              'RotaFácil',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
        ],
      ],
    );
  }
}
