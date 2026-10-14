import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/bookings_screen.dart';
import '../common/favorites_screen.dart';
import '../common/profile_tab.dart';
import 'tourist_home_tab.dart';

class TouristShell extends StatefulWidget {
  const TouristShell({super.key});

  @override
  State<TouristShell> createState() => _TouristShellState();
}

class _TouristShellState extends State<TouristShell> {
  int index = 0;

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
      backgroundColor: AppColors.cream,
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
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Reservas',
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
