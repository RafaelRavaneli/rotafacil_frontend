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
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: Colors.transparent,
        height: 52,
        elevation: 12,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.forest
                : AppColors.muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.forest
                : AppColors.muted,
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
    );
  }
}
