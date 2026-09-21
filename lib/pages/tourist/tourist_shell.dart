import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/bookings_screen.dart';
import '../common/messages_screen.dart';
import '../common/profile_tab.dart';
import 'tourist_home_tab.dart';
import 'trail_search_screen.dart';

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
        return const _ExploreTab();
      case 2:
        return const BookingsScreen(
          role: 'turista',
        );
      case 3:
        return const MessagesScreen(
          role: 'turista',
        );
      case 4:
        return const ProfileTab(
          role: 'Turista',
        );
      default:
        return const TouristHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
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
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.calendar_month_outlined,
            ),
            selectedIcon: Icon(
              Icons.calendar_month_rounded,
            ),
            label: 'Agendamentos',
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

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Explorar',
              style: TextStyle(
                color: AppColors.green900,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Encontre trilhas por cidade, dificuldade, data ou proximidade.',
              style: TextStyle(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TrailSearchScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.search_rounded,
              ),
              label: const Text(
                'Abrir busca com filtros',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
