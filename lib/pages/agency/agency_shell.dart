import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/bookings_screen.dart';
import '../common/profile_tab.dart';
import '../common/trails_management_screen.dart';
import 'agency_dashboard_tab.dart';
import 'guides_screen.dart';

class AgencyShell extends StatefulWidget {
  const AgencyShell({super.key});

  @override
  State<AgencyShell> createState() => _AgencyShellState();
}

class _AgencyShellState extends State<AgencyShell> {
  int index = 0;

  Widget _currentPage() {
    switch (index) {
      case 0:
        return const AgencyDashboardTab();
      case 1:
        return const GuidesScreen();
      case 2:
        return const TrailsManagementScreen(isAgency: true);
      case 3:
        return const BookingsScreen(role: 'agencia');
      case 4:
        return const ProfileTab(role: 'Agência');
      default:
        return const AgencyDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      // Constrói apenas a página selecionada.
      // Isso evita que abas pesadas escondidas bloqueiem
      // a interface inteira no Chrome.
      body: KeyedSubtree(key: ValueKey<int>(index), child: _currentPage()),

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          if (value == index) return;

          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Painel',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: 'Guias',
          ),
          NavigationDestination(
            icon: Icon(Icons.terrain_outlined),
            selectedIcon: Icon(Icons.terrain_rounded),
            label: 'Trilhas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agendamentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
