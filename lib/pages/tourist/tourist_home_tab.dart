import 'package:flutter/material.dart';

import '../../data/demo_data.dart' show guides;
import '../../models/guide.dart';
import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/market_search.dart';
import '../../widgets/network_image_box.dart';
import '../common/notification_center_screen.dart';
import 'guide_profile_screen.dart';
import 'trail_details_screen.dart';
import 'trail_search_screen.dart';

class TouristHomeTab extends StatelessWidget {
  const TouristHomeTab({super.key, this.exploreMode = false});

  final bool exploreMode;

  void _openTrail(BuildContext context, Trail trail) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrailDetailsScreen(trail: trail)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final trails = store.trails;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RotaFácil',
                              style: TextStyle(
                                color: AppColors.green800,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 18),
                            Text(
                              'Olá, Aventureiro! 👋',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Que trilha você quer explorar hoje?',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
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
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.ink,
                            ),
                          ),
                          if (store.unreadNotifications > 0)
                            Positioned(
                              right: 5,
                              top: 4,
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: MarketSearch(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrailSearchScreen(),
                        ),
                      );
                    },
                    hint: 'Buscar por cidade, dificuldade, data ou GPS...',
                  ),
                ),
              ),
              if (trails.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Nenhuma trilha cadastrada.')),
                )
              else ...[
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Destaque da semana',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _FeaturedTrailCard(
                      trail: trails.first,
                      favorite: store.isFavorite(trails.first.id),
                      onFavorite: () => store.toggleFavorite(trails.first.id),
                      onTap: () => _openTrail(context, trails.first),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Guias disponíveis',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 142,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: guides.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final guide = guides[index];

                        return _GuideHomeCard(
                          guide: guide,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GuideProfileScreen(guide: guide),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Mais trilhas',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: trails.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final trail = trails[index];
                      return _CompactTrailCard(
                        trail: trail,
                        onTap: () => _openTrail(context, trail),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedTrailCard extends StatelessWidget {
  const _FeaturedTrailCard({
    required this.trail,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final Trail trail;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              SizedBox(
                height: 210,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImageBox(url: trail.imageUrl, borderRadius: 0),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xC5152F20)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
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
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton.filledTonal(
                        onPressed: onFavorite,
                        icon: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite ? AppColors.red : AppColors.green900,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trail.name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trail.location,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${trail.distanceKm} km',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '★ ${trail.rating}',
                      style: const TextStyle(
                        color: AppColors.green700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'R\$ ${trail.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTrailCard extends StatelessWidget {
  const _CompactTrailCard({required this.trail, required this.onTap});

  final Trail trail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 86,
                child: NetworkImageBox(url: trail.imageUrl, borderRadius: 13),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trail.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trail.location,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${trail.difficulty} • ${trail.distanceKm} km',
                      style: const TextStyle(
                        color: AppColors.green700,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideHomeCard extends StatelessWidget {
  const _GuideHomeCard({required this.guide, required this.onTap});

  final GuideProfile guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: 'Abrir perfil de ${guide.name}',
        child: Material(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 104,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: NetworkImageBox(
                        url: guide.imageUrl,
                        borderRadius: 30,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            guide.name.split(' ').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (guide.verified) ...[
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.green700,
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '★ ${guide.rating}  •  Ver perfil',
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.green700,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
