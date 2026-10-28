import '../../models/local_booking.dart';
import '../../widgets/backend_refresh.dart';
import 'package:flutter/material.dart';
import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/run_action.dart';
import '../../utils/trail_schedule.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/scheduled_trail_card.dart';
import '../agency/guides_screen.dart';
import '../../navigation/app_routes.dart';
import '../management/trail_form_screen.dart';
import 'notification_center_screen.dart';
import 'trail_participants_screen.dart';
import 'trails_management_screen.dart';

/// Shared presentation; existing store and server still determine data access.
class OperatorDashboard extends StatelessWidget {
  const OperatorDashboard({
    super.key,
    required this.isAgency,
    this.onOpenTrails,
  });
  final bool isAgency;
  final VoidCallback? onOpenTrails;

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

  void _openParticipants(BuildContext context, Trail trail) {
    AppRoutes.push(
      context,
      AppRoutes.trailParticipants(trail.id),
      (_) => TrailParticipantsScreen(trail: trail),
    );
  }

  void _openEdit(BuildContext context, Trail trail) {
    AppRoutes.push(
      context,
      AppRoutes.editTrail(trail.id),
      (_) => TrailFormScreen(isAgency: isAgency, existing: trail),
    );
  }

  Future<void> _deactivate(BuildContext context, Trail trail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desativar roteiro?'),
        content: Text(
          'O roteiro "${trail.name}" deixará de aparecer na busca. Reservas ativas impedem a desativação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final saved = await runAction(
      context,
      () => AppStore.instance.removeTrail(trail),
    );
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${trail.name} foi desativado.')));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return BackendRefresh(
      child: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final user = isAgency ? store.agency : store.guide;
            final trails = store.managedTrails;
            final bookings = store.bookings
                .where(
                  (b) =>
                      isAgency ||
                      b.roleView == 'guia' ||
                      b.roleView == 'turista',
                )
                .toList();
            final activeBookings = bookings
                .where((b) => BookingStatus.isActive(b.status))
                .toList();
            final summary = store.operatorDashboardSummary;
            final now = DateTime.now();
            final upcomingTrails = upcomingTrailsOnce(
              trails,
              now: now,
              through: now.add(const Duration(days: 30)),
            );
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Painel',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        Material(
                          color: AppColors.white,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Notificações',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationCenterScreen(),
                              ),
                            ),
                            icon: Badge(
                              isLabelVisible: store.unreadNotifications > 0,
                              label: Text('${store.unreadNotifications}'),
                              child: const Icon(Icons.notifications_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
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
                                    color: AppColors.ink,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Organize seus roteiros e acompanhe as reservas.',
                                  style: TextStyle(
                                    color: AppColors.muted,
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
                            : (constraints.maxWidth - 36) / 4;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _Metric(
                              width: width,
                              label: 'Roteiros cadastrados',
                              value: '${trails.length}',
                              icon: Icons.terrain,
                            ),
                            _Metric(
                              width: width,
                              label: 'Roteiros ativos',
                              value:
                                  '${trails.where((t) => TrailStatus.isActive(t.status)).length}',
                              icon: Icons.check_circle_outline,
                            ),
                            _Metric(
                              width: width,
                              label: 'Reservas ativas',
                              value:
                                  '${summary?.active ?? activeBookings.length}',
                              icon: Icons.event_outlined,
                            ),
                            _Metric(
                              width: width,
                              label: 'Valor declarado',
                              value:
                                  'R\$ ${(summary?.declaredValue ?? activeBookings.fold<double>(0, (total, item) => total + item.valuePaid)).toStringAsFixed(2).replaceAll('.', ',')}',
                              icon: Icons.receipt_long_outlined,
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
                      onPressed: () => AppRoutes.push(
                        context,
                        AppRoutes.newTrail,
                        (_) => TrailFormScreen(isAgency: isAgency),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Criar novo roteiro'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _open(
                        context,
                        TrailsManagementScreen(isAgency: isAgency),
                        'Gestão de roteiros',
                      ),
                      icon: const Icon(Icons.terrain_outlined),
                      label: const Text('Gerenciar roteiros'),
                    ),
                    if (isAgency) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GuidesScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.people_outline),
                        label: const Text('Guias e convites'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Roteiros dos próximos 30 dias',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Roteiros com início previsto nos próximos 30 dias.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed:
                          onOpenTrails ??
                          () => _open(
                            context,
                            TrailsManagementScreen(isAgency: isAgency),
                            'Roteiros',
                          ),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Ver todos os roteiros'),
                    ),
                    const SizedBox(height: 16),
                    if (upcomingTrails.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhum roteiro previsto para os próximos 30 dias.',
                          ),
                        ),
                      ),
                    ...upcomingTrails.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ScheduledTrailCard(
                          trail: item.trail,
                          departure: item.departure,
                          onParticipants: () =>
                              _openParticipants(context, item.trail),
                          onEdit: () => _openEdit(context, item.trail),
                          onDeactivate: () => _deactivate(context, item.trail),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
  final String value;
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
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
