import 'package:flutter/material.dart';

import '../../data/demo_data.dart' show guideByName;

import '../../models/local_booking.dart';
import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import 'guide_profile_screen.dart';

class TrailDetailsScreen extends StatelessWidget {
  const TrailDetailsScreen({
    super.key,
    required this.trail,
  });

  final Trail trail;

  Future<void> _book(BuildContext context) async {
    bool confirmed = false;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirmar agendamento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                trail.name,
                style: const TextStyle(
                  color: AppColors.green700,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.green700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trail.date.isEmpty
                        ? 'Data a combinar'
                        : trail.date,
                  ),
                  const Spacer(),
                  Text(
                    'R\$ ${trail.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  await AppStore.instance.addBooking(
                    LocalBooking(
                      id: DateTime.now()
                          .microsecondsSinceEpoch
                          .toString(),
                      trailId: trail.id,
                      trailName: trail.name,
                      personName:
                          AppStore.instance.tourist.name,
                      date: trail.date.isEmpty
                          ? 'Data a combinar'
                          : trail.date,
                      status: 'Confirmado',
                      roleView: 'turista',
                      valuePaid: trail.price,
                    ),
                  );

                  confirmed = true;

                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || !confirmed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Agendamento salvo. Confira a aba Agendamentos.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final responsibleGuide = guideByName(trail.guideName);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final favorite = store.isFavorite(trail.id);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.paper,
                foregroundColor: AppColors.ink,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor:
                        AppColors.paper.withValues(alpha: .92),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: AppColors.paper
                          .withValues(alpha: .92),
                      child: IconButton(
                        onPressed: () =>
                            store.toggleFavorite(trail.id),
                        icon: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite
                              ? AppColors.red
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: NetworkImageBox(
                    url: trail.imageUrl,
                    borderRadius: 0,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      22,
                      22,
                      120,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green700,
                            borderRadius:
                                BorderRadius.circular(99),
                          ),
                          child: Text(
                            trail.difficulty,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          trail.name,
                          style: const TextStyle(
                            color: AppColors.green900,
                            fontSize: 30,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.green700,
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trail.location,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trail.rating} (${trail.reviews})',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChipMetric(
                              icon: Icons.route_rounded,
                              value:
                                  '${trail.distanceKm} km',
                            ),
                            _ChipMetric(
                              icon: Icons.schedule_rounded,
                              value: trail.duration,
                            ),
                            _ChipMetric(
                              icon: Icons.terrain_rounded,
                              value:
                                  '${trail.elevation} m',
                            ),
                            _ChipMetric(
                              icon: Icons.hiking_rounded,
                              value: trail.modality,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text(
                          'Sobre a trilha',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trail.description,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13.5,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (trail.latitude != null &&
                            trail.longitude != null)
                          Container(
                            padding:
                                const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.green100,
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.map_outlined,
                                  color:
                                      AppColors.green700,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Ponto da trilha: ${trail.latitude!.toStringAsFixed(5)}, ${trail.longitude!.toStringAsFixed(5)}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Text(
                          'Guia responsável',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: responsibleGuide == null
                              ? const CircleAvatar(
                                  backgroundColor: AppColors.green100,
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: AppColors.green700,
                                  ),
                                )
                              : SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: NetworkImageBox(
                                    url: responsibleGuide.imageUrl,
                                    borderRadius: 24,
                                  ),
                                ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  trail.guideName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (responsibleGuide?.verified ?? false) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.green700,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            responsibleGuide == null
                                ? 'Responsável pela experiência'
                                : '★ ${responsibleGuide.rating} • Toque para ver o perfil',
                          ),
                          trailing: responsibleGuide == null
                              ? null
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: responsibleGuide == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GuideProfileScreen(
                                        guide: responsibleGuide,
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'R\$ ${trail.price.toStringAsFixed(2)}\npor pessoa',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _book(context),
                  icon: const Icon(Icons.hiking_rounded),
                  label: const Text('Agendar trilha'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipMetric extends StatelessWidget {
  const _ChipMetric({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.green800,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
