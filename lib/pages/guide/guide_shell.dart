import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/role_navigation_bar.dart';
import '../../widgets/animated_tab_body.dart';
import '../../state/app_store.dart';
import '../common/bookings_screen.dart';
import '../common/profile_tab.dart';
import '../common/trails_management_screen.dart';
import 'guide_dashboard_tab.dart';

class GuideShell extends StatefulWidget {
  const GuideShell({super.key});

  @override
  State<GuideShell> createState() => _GuideShellState();
}

class _GuideShellState extends State<GuideShell> {
  int index = 0;

  Widget _currentPage() {
    switch (index) {
      case 0:
        return GuideDashboardTab(
          onOpenBookings: () => setState(() => index = 2),
        );
      case 1:
        return const TrailsManagementScreen(isAgency: false);
      case 2:
        return const BookingsScreen(role: 'guia');
      case 3:
        return const ProfileTab(role: 'Guia');
      default:
        return GuideDashboardTab(
          onOpenBookings: () => setState(() => index = 2),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,

      // Importante:
      // Não usamos mais IndexedStack.
      // IndexedStack construía TODAS as abas ao mesmo tempo,
      // inclusive telas escondidas com listas, imagens e listeners.
      // Agora apenas a aba selecionada é montada.
      body: AnimatedTabBody(index: index, child: _currentPage()),

      bottomNavigationBar: RoleNavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          if (value == index) return;

          setState(() {
            index = value;
          });
          unawaited(AppStore.instance.refreshBackend());
        },
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
