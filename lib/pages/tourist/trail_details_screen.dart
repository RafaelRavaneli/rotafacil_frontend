import 'package:flutter/material.dart';

import '../../utils/run_action.dart';

import '../../data/demo_data.dart' show guideByName;

import '../../models/local_booking.dart';
import '../../models/trail.dart';
import '../../models/trail_experience.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/trail_location_map.dart';
import '../../utils/date_time_format.dart';
import 'guide_profile_screen.dart';

class TrailDetailsScreen extends StatefulWidget {
  const TrailDetailsScreen({super.key, required this.trail});

  final Trail trail;

  @override
  State<TrailDetailsScreen> createState() => _TrailDetailsScreenState();
}

class _TrailDetailsScreenState extends State<TrailDetailsScreen> {
  Trail get trail => widget.trail;
  late Future<List<TrailReview>> reviewsFuture;
  late Future<TrailWeather?> weatherFuture;

  @override
  void initState() {
    super.initState();
    final store = AppStore.instance;
    reviewsFuture = store.reviewsFor(trail.id);
    weatherFuture = trail.latitude == null || trail.longitude == null
        ? Future<TrailWeather?>.value(null)
        : store.weatherFor(trail.id);
  }

  Future<void> _book(BuildContext context) async {
    final now = DateTime.now();
    final available = trail.effectiveDepartures
        .where((item) => !item.startsAt.isBefore(now))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este roteiro não possui datas disponíveis.'),
        ),
      );
      return;
    }
    TrailDeparture? selected = available.length == 1
        ? available.first
        : await showModalBottomSheet<TrailDeparture>(
            context: context,
            showDragHandle: true,
            backgroundColor: AppColors.paper,
            builder: (context) => SafeArea(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: available.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final departure = available[index];
                  return ListTile(
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text(formatBrazilianDateTime(departure.startsAt)),
                    subtitle: Text(
                      'Término: ${formatBrazilianDateTime(departure.endsAt)}',
                    ),
                    onTap: () => Navigator.pop(context, departure),
                  );
                },
              ),
            ),
          );
    if (selected == null || !context.mounted) return;
    final departure = selected;
    bool confirmed = false;
    bool submitting = false;

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
                'Confirme sua reserva',
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
                  Expanded(
                    child: Text(formatBrazilianDateTime(departure.startsAt)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'R\$ ${trail.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta reserva não realiza pagamento online.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (submitting) return;
                  submitting = true;
                  final saved = await runAction(
                    sheetContext,
                    () => AppStore.instance.addBooking(
                      LocalBooking(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        trailId: trail.id,
                        trailName: trail.name,
                        personName: AppStore.instance.tourist.name,
                        date: _apiDate(departure.startsAt),
                        status: 'Confirmado',
                        roleView: 'turista',
                        valuePaid: trail.price,
                        departureId: departure.id,
                        startsAt: departure.startsAt.toIso8601String(),
                        endsAt: departure.endsAt.toIso8601String(),
                      ),
                    ),
                  );

                  submitting = false;
                  if (!saved) return;
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
      const SnackBar(content: Text('Reserva salva. Confira a aba Reservas.')),
    );
  }

  String _apiDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final responsibleGuide = store.useBackend
        ? null
        : guideByName(trail.guideName);
    final hasRemoteGuide =
        store.useBackend &&
        trail.guideId.isNotEmpty &&
        trail.responsibleRole == 'guia';

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
                    backgroundColor: AppColors.paper.withValues(alpha: .92),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: AppColors.paper.withValues(alpha: .92),
                      child: IconButton(
                        onPressed: () => runAction(
                          context,
                          () => store.toggleFavorite(trail.id),
                        ),
                        icon: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite ? AppColors.red : AppColors.ink,
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
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green700,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            trail.difficulty,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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
                          ],
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChipMetric(
                              icon: Icons.route_rounded,
                              value: trail.distanceLabel,
                            ),
                            _ChipMetric(
                              icon: Icons.hiking_rounded,
                              value: trail.effectiveActivities.join(' • '),
                            ),
                            _ChipMetric(
                              icon: Icons.groups_outlined,
                              value: '${trail.capacity} vagas',
                            ),
                            if (trail.startTime.isNotEmpty &&
                                trail.endTime.isNotEmpty)
                              _ChipMetric(
                                icon: Icons.schedule_outlined,
                                value: '${trail.startTime}–${trail.endTime}',
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text(
                          'Sobre o roteiro',
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
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            trail.accessible
                                ? Icons.accessible_forward_rounded
                                : Icons.info_outline_rounded,
                            color: AppColors.green700,
                          ),
                          title: Text(
                            trail.accessible
                                ? 'Percurso informado como acessível'
                                : 'Acessibilidade não informada',
                          ),
                        ),
                        if (trail.recommendedItems.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Itens recomendados',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: trail.recommendedItems
                                .map(
                                  (item) => Chip(
                                    avatar: const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                    ),
                                    label: Text(item),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (trail.route.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Percurso cadastrado: ${trail.route.length} ponto${trail.route.length == 1 ? '' : 's'}.',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                        const SizedBox(height: 14),
                        FutureBuilder<TrailWeather?>(
                          future: weatherFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            final weather = snapshot.data;
                            if (weather == null) return const SizedBox.shrink();
                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.cloud_outlined,
                                  color: AppColors.green700,
                                ),
                                title: Text(weather.condition),
                                subtitle: Text(
                                  '${weather.minimumTemperature?.toStringAsFixed(0) ?? '-'} °C a '
                                  '${weather.maximumTemperature?.toStringAsFixed(0) ?? '-'} °C • '
                                  '${weather.rainProbability ?? 0}% de chuva',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        if (trail.latitude != null && trail.longitude != null)
                          TrailLocationMap(trail: trail),
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
                                  trail.responsibleName,
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
                            responsibleGuide != null || hasRemoteGuide
                                ? 'Ver perfil do responsável'
                                : 'Responsável pela experiência',
                          ),
                          trailing: responsibleGuide == null && !hasRemoteGuide
                              ? null
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: responsibleGuide == null && !hasRemoteGuide
                              ? null
                              : () async {
                                  final guide =
                                      responsibleGuide ??
                                      await runValueAction(
                                        context,
                                        () => store.publicGuide(trail.guideId),
                                      );
                                  if (guide == null || !context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GuideProfileScreen(guide: guide),
                                    ),
                                  );
                                },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Avaliações',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<TrailReview>>(
                          future: reviewsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return const Text(
                                'Não foi possível carregar as avaliações.',
                                style: TextStyle(color: AppColors.muted),
                              );
                            }
                            final reviews = snapshot.data ?? const [];
                            if (reviews.isEmpty) {
                              return const Text(
                                'Este roteiro ainda não possui avaliações.',
                                style: TextStyle(color: AppColors.muted),
                              );
                            }
                            return Column(
                              children: reviews
                                  .map(
                                    (review) => Card(
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.green100,
                                          child: Text(
                                            review.rating.toString(),
                                            style: const TextStyle(
                                              color: AppColors.green800,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        title: Text(review.userName),
                                        subtitle: Text(
                                          review.comment.trim().isEmpty
                                              ? 'Sem comentário.'
                                              : review.comment,
                                        ),
                                        trailing: const Icon(
                                          Icons.star_rounded,
                                          color: AppColors.earth,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
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
            border: Border(top: BorderSide(color: AppColors.border)),
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
                  label: const Text('Reservar'),
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
  const _ChipMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.green800, size: 17),
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
