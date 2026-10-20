import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/role_navigation_bar.dart';
import '../../widgets/animated_tab_body.dart';
import '../../state/app_store.dart';
import '../../navigation/app_routes.dart';
import '../common/bookings_screen.dart';
import '../common/favorites_screen.dart';
import '../common/profile_tab.dart';
import 'tourist_home_tab.dart';

class TouristShell extends StatefulWidget {
  const TouristShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<TouristShell> createState() => _TouristShellState();
}

class _TouristShellState extends State<TouristShell> {
  late int index = widget.initialIndex;

  Widget _currentPage() {
    switch (index) {
      case 0:
        return const TouristHomeTab();
      case 1:
        return const FavoritesScreen();
      case 2:
        return const BookingsScreen(role: 'turista');
      case 3:
        return const ProfileTab(role: 'Turista');
      default:
        return const TouristHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: AnimatedTabBody(index: index, child: _currentPage()),
      bottomNavigationBar: RoleNavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          if (value == index) return;

          setState(() {
            index = value;
          });
          unawaited(
            AppRoutes.replaceBrowserLocation(
              AppRoutes.tabsForRole('turista')[value],
            ),
          );
          unawaited(AppStore.instance.refreshBackend());
        },
        destinations: const [
          RoleNavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Explorar',
          ),
          RoleNavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favoritos',
          ),
          RoleNavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Reservas',
          ),
          RoleNavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
