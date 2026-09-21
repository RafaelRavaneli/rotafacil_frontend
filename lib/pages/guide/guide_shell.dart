import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/bookings_screen.dart';
import '../common/messages_screen.dart';
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
        return const GuideDashboardTab();
      case 1:
        return const TrailsManagementScreen(
          isAgency: false,
        );
      case 2:
        return const BookingsScreen(
          role: 'guia',
        );
      case 3:
        return const MessagesScreen(
          role: 'guia',
        );
      case 4:
        return const ProfileTab(
          role: 'Guia',
        );
      default:
        return const GuideDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      // Importante:
      // Não usamos mais IndexedStack.
      // IndexedStack construía TODAS as abas ao mesmo tempo,
      // inclusive telas escondidas com listas, imagens e listeners.
      // Agora apenas a aba selecionada é montada.
      body: KeyedSubtree(
        key: ValueKey<int>(index),
        child: _currentPage(),
      ),

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
            icon: Icon(Icons.terrain_outlined),
            selectedIcon: Icon(Icons.terrain_rounded),
            label: 'Trilhas',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.calendar_month_outlined,
            ),
            selectedIcon: Icon(
              Icons.calendar_month_rounded,
            ),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.chat_bubble_rounded,
            ),
            label: 'Mensagens',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
