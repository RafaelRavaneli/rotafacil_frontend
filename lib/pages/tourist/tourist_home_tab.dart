import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../state/app_store.dart';
import '../../models/trail.dart';
import '../../theme/app_colors.dart';
import '../../widgets/market_search.dart';
import '../../widgets/trail_card.dart';
import '../../utils/run_action.dart';
import '../../navigation/app_routes.dart';
import '../../services/location_service.dart';
import 'trail_details_screen.dart';
import 'trail_search_screen.dart';

class TouristHomeTab extends StatefulWidget {
  const TouristHomeTab({super.key, this.exploreMode = false});
  final bool exploreMode;

  @override
  State<TouristHomeTab> createState() => _TouristHomeTabState();
}

class _TouristHomeTabState extends State<TouristHomeTab> {
  UserCoordinates? position;
  bool locationLoaded = true;
  String? locationError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPosition());
  }

  void _finishLocationWithError(String message) {
    if (!mounted) return;
    setState(() {
      position = null;
      locationLoaded = true;
      locationError = message;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadPosition() async {
    setState(() {
      locationLoaded = false;
      locationError = null;
    });
    try {
      final current = await LocationService.instance.capture();
      if (mounted) {
        setState(() {
          position = current;
          locationLoaded = true;
          locationError = null;
        });
      }
    } catch (error) {
      _finishLocationWithError(
        error is StateError
            ? error.message.toString()
            : 'Não foi possível obter sua localização. Verifique o GPS e tente novamente.',
      );
    }
  }

  double? _distanceTo(Trail trail) {
    final current = position;
    if (current == null || trail.latitude == null || trail.longitude == null) {
      return null;
    }
    return Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          trail.latitude!,
          trail.longitude!,
        ) /
        1000;
  }

  bool _isModality(Trail trail, List<String> terms) {
    return trail.effectiveActivities.any((activity) {
      final value = activity.toLowerCase();
      return terms.any(value.contains);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final trails = store.trails
              .where((t) => TrailStatus.isActive(t.status))
              .toList();
          final nearby =
              trails.where((trail) {
                final distance = _distanceTo(trail);
                return distance != null && distance <= 100;
              }).toList()..sort(
                (a, b) => (_distanceTo(a) ?? double.infinity).compareTo(
                  _distanceTo(b) ?? double.infinity,
                ),
              );
          final bestRated = trails.where((trail) => trail.rating > 0).toList()
            ..sort((a, b) {
              final rating = b.rating.compareTo(a.rating);
              return rating != 0 ? rating : b.reviews.compareTo(a.reviews);
            });
          final trekking = trails
              .where(
                (trail) => _isModality(trail, const [
                  'trilha',
                  'trekking',
                  'caminhada',
                ]),
              )
              .toList();
          final aquatrekking = trails
              .where(
                (trail) =>
                    _isModality(trail, const ['aquatrekking', 'aqua trekking']),
              )
              .toList();
          final camping = trails
              .where(
                (trail) => _isModality(trail, const ['acampamento', 'camping']),
              )
              .toList();
          final name = store.tourist.name.trim().split(' ').first;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Explore atividades' : 'Olá, $name',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Encontre sua próxima experiência ao ar livre.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 22),
                          MarketSearch(
                            onTap: () => AppRoutes.push(
                              context,
                              AppRoutes.search,
                              (_) => const TrailSearchScreen(),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  SliverList.list(
                    children: [
                      _TrailCarouselSection(
                        title: 'Atividades próximas',
                        subtitle: 'Até 100 km da sua localização',
                        trails: nearby,
                        loading: !locationLoaded,
                        emptyText: position == null
                            ? (locationError ??
                                  'Permita a localização para ver atividades próximas.')
                            : 'Nenhuma atividade encontrada em até 100 km.',
                        emptyAction: position == null
                            ? () => unawaited(_loadPosition())
                            : null,
                        emptyActionLabel: 'Usar minha localização',
                        itemBuilder: (trail) => _card(context, trail, store),
                      ),
                      _TrailCarouselSection(
                        title: 'Melhores avaliados',
                        subtitle: 'Experiências preferidas pelos usuários',
                        trails: bestRated,
                        emptyText: 'Ainda não existem atividades avaliadas.',
                        itemBuilder: (trail) => _card(context, trail, store),
                      ),
                      _TrailCarouselSection(
                        title: 'Roteiros com trilha',
                        subtitle: 'Caminhadas e trekking',
                        trails: trekking,
                        emptyText:
                            'Nenhum roteiro com trilha disponível no momento.',
                        itemBuilder: (trail) => _card(context, trail, store),
                      ),
                      _TrailCarouselSection(
                        title: 'Aquatrekking',
                        subtitle: 'Percursos que combinam água e caminhada',
                        trails: aquatrekking,
                        emptyText: 'Nenhum aquatrekking disponível no momento.',
                        itemBuilder: (trail) => _card(context, trail, store),
                      ),
                      _TrailCarouselSection(
                        title: 'Acampamentos',
                        subtitle: 'Experiências para permanecer na natureza',
                        trails: camping,
                        emptyText: 'Nenhum acampamento disponível no momento.',
                        itemBuilder: (trail) => _card(context, trail, store),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, Trail trail, AppStore store) => TrailCard(
    trail: trail,
    favorite: store.isFavorite(trail.id),
    onFavorite: () => runAction(context, () => store.toggleFavorite(trail.id)),
    onTap: () => AppRoutes.push(
      context,
      AppRoutes.trail(trail.id),
      (_) => TrailDetailsScreen(trail: trail),
    ),
  );
}

class _TrailCarouselSection extends StatelessWidget {
  const _TrailCarouselSection({
    required this.title,
    required this.subtitle,
    required this.trails,
    required this.emptyText,
    required this.itemBuilder,
    this.loading = false,
    this.emptyAction,
    this.emptyActionLabel,
  });

  final String title;
  final String subtitle;
  final List<Trail> trails;
  final String emptyText;
  final Widget Function(Trail trail) itemBuilder;
  final bool loading;
  final VoidCallback? emptyAction;
  final String? emptyActionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 34),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (trails.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emptyText,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    if (emptyAction != null) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: emptyAction,
                        icon: const Icon(Icons.my_location_rounded),
                        label: Text(emptyActionLabel ?? 'Tentar novamente'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 345,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: trails.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) =>
                    SizedBox(width: 270, child: itemBuilder(trails[index])),
              ),
            ),
        ],
      ),
    );
  }
}
