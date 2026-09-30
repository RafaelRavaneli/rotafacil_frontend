import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/profile_avatar.dart';
import '../common/bookings_screen.dart';
import '../common/notification_center_screen.dart';
import '../common/settings/personal_data_screen.dart';
import '../common/trails_management_screen.dart';
import '../management/trail_form_screen.dart';
import 'guides_screen.dart';

class AgencyDashboardTab extends StatelessWidget {
  const AgencyDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final activeGuides = store.agencyGuides
              .where((guide) => guide.status == 'Ativo')
              .length;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      ProfileAvatar(
                        dataUrl: store.agency.profileImageDataUrl,
                        radius: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.agency.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Row(
                              children: [
                                Text(
                                  'Agência verificada',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11.5,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 15,
                                  color: AppColors.green700,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PersonalDataScreen(role: 'Agência'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationCenterScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _AgencyStat(
                          value: '$activeGuides',
                          label: 'Guias Ativos',
                          icon: Icons.groups_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _AgencyStat(
                          value: '${store.managedTrails.length}',
                          label: 'Trilhas',
                          icon: Icons.terrain_outlined,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _AgencyStat(
                          value: '${store.bookings.length}',
                          label: 'Agendamentos',
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: _AgencyStat(
                          value: '4,8',
                          label: 'Avaliação',
                          icon: Icons.star_rounded,
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
                          'Guias da agência',
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
                              builder: (_) => const GuidesScreen(),
                            ),
                          );
                        },
                        child: const Text('Gerenciar'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 112,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: store.agencyGuides.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final guide = store.agencyGuides[index];

                      return Container(
                        width: 108,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.green100,
                              child: Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: AppColors.green700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              guide.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              guide.status,
                              style: const TextStyle(
                                color: AppColors.green700,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                          'Trilhas gerenciadas',
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
                                body: TrailsManagementScreen(isAgency: true),
                              ),
                            ),
                          );
                        },
                        child: const Text('Gerenciar'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: store.managedTrails.length > 3
                      ? 3
                      : store.managedTrails.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final trail = store.managedTrails[index];

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 58,
                            height: 48,
                            child: NetworkImageBox(
                              url: trail.imageUrl,
                              borderRadius: 10,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trail.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.5,
                                  ),
                                ),
                                Text(
                                  trail.location,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            trail.status,
                            style: const TextStyle(
                              color: AppColors.green700,
                              fontSize: 9.5,
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrailFormScreen(isAgency: true),
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
                            body: BookingsScreen(role: 'agencia'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Ver agendamentos'),
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

class _AgencyStat extends StatelessWidget {
  const _AgencyStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 91,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
          ),
          const Spacer(),
          Icon(icon, color: AppColors.green700, size: 17),
        ],
      ),
    );
  }
}
