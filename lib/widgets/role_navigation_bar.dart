import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RoleNavigationDestination {
  const RoleNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}

class RoleNavigationBar extends StatelessWidget {
  const RoleNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<RoleNavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.paper,
          surfaceTintColor: Colors.transparent,
          // Item ativo com "pílula" clara, como no Figma.
          indicatorColor: AppColors.sage,
          indicatorShape: const StadiumBorder(),
          height: 64,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              size: 22,
              color: states.contains(WidgetState.selected)
                  ? AppColors.leaf
                  : AppColors.leaf.withValues(alpha: .8),
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.leaf
                  : AppColors.leaf.withValues(alpha: .8),
              fontSize: destinations.length > 4 ? 10 : 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w500,
            );
          }),
        ),
        child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final item in destinations)
            NavigationDestination(
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: item.label,
            ),
        ],
      ),
      ),
    );
  }
}
