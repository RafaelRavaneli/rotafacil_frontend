import 'package:flutter/material.dart';

import '../../models/guide.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/trail_card.dart';
import '../../utils/run_action.dart';
import 'trail_details_screen.dart';

class GuideProfileScreen extends StatelessWidget {
  const GuideProfileScreen({super.key, required this.guide});
  final GuideProfile guide;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do guia')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final trails = store.trails
              .where(
                (trail) =>
                    trail.guideId == guide.id ||
                    (trail.guideId.isEmpty &&
                        trail.guideName.toLowerCase() ==
                            guide.name.toLowerCase()),
              )
              .toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: NetworkImageBox(
                        url: guide.imageUrl,
                        borderRadius: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    guide.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  if (guide.city.isNotEmpty || guide.state.isNotEmpty)
                    Text(
                      [
                        guide.city,
                        guide.state,
                      ].where((item) => item.isNotEmpty).join(' / '),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  if (guide.verified)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: AppColors.forest,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text('Perfil verificado'),
                        ],
                      ),
                    ),
                  if (guide.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Sobre',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(guide.bio),
                  ],
                  if (guide.specialties.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Especialidades',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: guide.specialties
                          .map((item) => Chip(label: Text(item)))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Roteiros deste guia',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (trails.isEmpty)
                    const Text('Nenhum roteiro disponível neste catálogo.'),
                  for (final trail in trails)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TrailCard(
                        trail: trail,
                        favorite: store.isFavorite(trail.id),
                        onFavorite: () => runAction(
                          context,
                          () => store.toggleFavorite(trail.id),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrailDetailsScreen(trail: trail),
                          ),
                        ),
                      ),
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
