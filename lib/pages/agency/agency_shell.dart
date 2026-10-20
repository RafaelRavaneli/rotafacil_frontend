import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/role_navigation_bar.dart';
import '../../widgets/animated_tab_body.dart';
import '../../state/app_store.dart';
import '../../navigation/app_routes.dart';
import '../common/bookings_screen.dart';
import '../common/profile_tab.dart';
import '../common/trails_management_screen.dart';
import 'agency_dashboard_tab.dart';
import 'guides_screen.dart';

class AgencyShell extends StatefulWidget {
  const AgencyShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AgencyShell> createState() => _AgencyShellState();
}

class _AgencyShellState extends State<AgencyShell> {
  late int index = widget.initialIndex;

  Widget _currentPage() {
    switch (index) {
      case 0:
        return AgencyDashboardTab(onOpenBookings: () => _selectTab(3));
      case 1:
        return const TrailsManagementScreen(isAgency: true);
      case 2:
        return const GuidesScreen();
      case 3:
        return const BookingsScreen(role: 'agencia');
      case 4:
        return const ProfileTab(role: 'Agência');
      default:
        return AgencyDashboardTab(onOpenBookings: () => _selectTab(3));
    }
  }

  void _selectTab(int value) {
    if (value == index) return;
    setState(() => index = value);
    unawaited(
      AppRoutes.replaceBrowserLocation(AppRoutes.tabsForRole('agencia')[value]),
    );
    unawaited(AppStore.instance.refreshBackend());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,

      // Constrói apenas a página selecionada.
      // Isso evita que abas pesadas escondidas bloqueiem
      // a interface inteira no Chrome.
      body: AnimatedTabBody(index: index, child: _currentPage()),

      bottomNavigationBar: RoleNavigationBar(
        selectedIndex: index,
        onDestinationSelected: _selectTab,
        destinations: const [
          RoleNavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Painel',
          ),
          RoleNavigationDestination(
            icon: Icon(Icons.terrain_outlined),
            selectedIcon: Icon(Icons.terrain_rounded),
            label: 'Roteiros',
          ),
          RoleNavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: 'Guias',
          ),
          RoleNavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
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
