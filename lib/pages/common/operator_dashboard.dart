import 'package:flutter/material.dart';
import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/booking_summary_card.dart';
import '../agency/guides_screen.dart';
import '../management/trail_form_screen.dart';
import 'booking_details_screen.dart';
import 'bookings_screen.dart';
import 'notification_center_screen.dart';
import 'trails_management_screen.dart';

/// Shared presentation; existing store and server still determine data access.
class OperatorDashboard extends StatelessWidget {
  const OperatorDashboard({super.key, required this.isAgency});
  final bool isAgency;

  void _open(BuildContext context, Widget page, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final user = isAgency ? store.agency : store.guide;
          final trails = store.managedTrails;
          final bookings = store.bookings
              .where(
                (b) =>
                    isAgency || b.roleView == 'guia' || b.roleView == 'turista',
              )
              .toList();
          final reservations = bookings.take(3).toList();
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isAgency ? 'RotaFácil · Agência' : 'RotaFácil · Guia',
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Notificações',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationCenterScreen(),
                          ),
                        ),
                        icon: Badge(
                          isLabelVisible: store.unreadNotifications > 0,
                          label: Text('${store.unreadNotifications}'),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          dataUrl: user.profileImageDataUrl,
                          radius: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá, ${user.name}!',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Organize suas trilhas e acompanhe as reservas.',
                                style: TextStyle(
                                  color: AppColors.sage,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth < 500
                          ? (constraints.maxWidth - 12) / 2
                          : (constraints.maxWidth - 24) / 3;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _Metric(
                            width: width,
                            label: 'Trilhas cadastradas',
                            value: trails.length,
                            icon: Icons.terrain,
                          ),
                          _Metric(
                            width: width,
                            label: 'Trilhas ativas',
                            value: trails
                                .where((t) => TrailStatus.isActive(t.status))
                                .length,
                            icon: Icons.check_circle_outline,
                          ),
                          _Metric(
                            width: width,
                            label: 'Reservas disponíveis',
                            value: bookings.length,
                            icon: Icons.event_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Gerencie sua operação',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrailFormScreen(isAgency: isAgency),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar nova trilha'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _open(
                      context,
                      TrailsManagementScreen(isAgency: isAgency),
                      'Gestão de trilhas',
                    ),
                    icon: const Icon(Icons.terrain_outlined),
                    label: const Text('Gerenciar trilhas'),
                  ),
                  if (isAgency) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GuidesScreen()),
                      ),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Guias e convites'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Reservas',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Consulte a situação e os detalhes das reservas disponíveis.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  if (reservations.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhuma reserva disponível.'),
                      ),
                    ),
                  ...reservations.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BookingSummaryCard(
                        booking: booking,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailsScreen(bookingId: booking.id),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _open(
                      context,
                      BookingsScreen(role: isAgency ? 'agencia' : 'guia'),
                      'Reservas',
                    ),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Ver todas as reservas'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });
  final double width;
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.leaf),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 26,
                color: AppColors.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
