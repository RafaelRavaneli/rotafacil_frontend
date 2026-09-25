import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/profile_avatar.dart';
import '../common/bookings_screen.dart';
import '../common/notification_center_screen.dart';
import '../common/trails_management_screen.dart';
import '../management/trail_form_screen.dart';

class GuideDashboardTab extends StatelessWidget {
  const GuideDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final upcoming = store.bookings
              .where((item) => item.status != 'Cancelado')
              .take(3)
              .toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Painel do Guia',
                          style: TextStyle(
                            color: AppColors.green800,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationCenterScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.notifications_none_rounded),
                          ),
                          if (store.unreadNotifications > 0)
                            Positioned(
                              right: 4,
                              top: 3,
                              child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  store.unreadNotifications > 9
                                      ? '9+'
                                      : '${store.unreadNotifications}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.green900,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          dataUrl: store.guide.profileImageDataUrl,
                          radius: 30,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá, ${store.guide.name}!',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Gerencie trilhas, reservas e sua operação.',
                                style: TextStyle(
                                  color: Color(0xFFD9E6DD),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          value: '${store.trails.length}',
                          label: 'Trilhas',
                          icon: Icons.terrain_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(
                          value: '${store.bookings.length}',
                          label: 'Agendamentos',
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: _Stat(
                          value: '4,9',
                          label: 'Avaliação',
                          icon: Icons.star_border_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Próximos agendamentos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Scaffold(
                                body: BookingsScreen(role: 'guia'),
                              ),
                            ),
                          );
                        },
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                ),
              ),
              if (upcoming.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Nenhum agendamento ativo.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: upcoming.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final booking = upcoming[index];
                      final matches = store.trails
                          .where((item) => item.id == booking.trailId)
                          .toList();

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 54,
                              height: 54,
                              child: matches.isNotEmpty
                                  ? NetworkImageBox(
                                      url: matches.first.imageUrl,
                                      borderRadius: 12,
                                    )
                                  : const DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppColors.green100,
                                      ),
                                      child: Icon(Icons.terrain_outlined),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.trailName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${booking.personName} • ${booking.date}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              booking.status,
                              style: const TextStyle(
                                color: AppColors.green700,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const TrailFormScreen(isAgency: false),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Criar nova trilha'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                sliver: SliverToBoxAdapter(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: TrailsManagementScreen(isAgency: false),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Gerenciar minhas trilhas'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.green800,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
          ),
          const Spacer(),
          Icon(icon, color: AppColors.green700, size: 18),
        ],
      ),
    );
  }
}
