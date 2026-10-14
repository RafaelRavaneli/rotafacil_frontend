import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../models/trail.dart';
import '../../theme/app_colors.dart';
import '../../widgets/market_search.dart';
import '../../widgets/trail_card.dart';
import '../../utils/run_action.dart';
import 'trail_details_screen.dart';
import 'trail_search_screen.dart';

class TouristHomeTab extends StatelessWidget {
  const TouristHomeTab({super.key, this.exploreMode = false});
  final bool exploreMode;

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
          final name = store.tourist.name.trim().split(' ').first;
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RotaFácil · Turista',
                                style: TextStyle(
                                  color: AppColors.forest,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name.isEmpty
                                    ? 'Explore as trilhas'
                                    : 'Olá, $name',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Descubra sua próxima trilha.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                              const SizedBox(height: 22),
                              MarketSearch(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TrailSearchScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Explore as trilhas',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              if (trails.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Text(
                                    'Nenhuma trilha disponível no momento.',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        sliver: SliverList.list(
                          children: [
                            for (
                              var index = 0;
                              index < trails.length;
                              index += wide ? 2 : 1
                            )
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _card(
                                        context,
                                        trails[index],
                                        store,
                                      ),
                                    ),
                                    if (wide) ...[
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: index + 1 < trails.length
                                            ? _card(
                                                context,
                                                trails[index + 1],
                                                store,
                                              )
                                            : const SizedBox(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, Trail trail, AppStore store) => TrailCard(
    trail: trail,
    favorite: store.isFavorite(trail.id),
    onFavorite: () => runAction(context, () => store.toggleFavorite(trail.id)),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrailDetailsScreen(trail: trail)),
    ),
  );
}
