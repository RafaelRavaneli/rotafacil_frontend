import 'package:flutter/material.dart';

import '../../models/guide.dart';
import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../common/messages_screen.dart';
import 'trail_details_screen.dart';

class GuideProfileScreen extends StatelessWidget {
  const GuideProfileScreen({
    super.key,
    required this.guide,
  });

  final GuideProfile guide;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Perfil do guia',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final guideTrails = store.trails
              .where(
                (trail) =>
                    trail.guideName.toLowerCase() ==
                    guide.name.toLowerCase(),
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _GuideHeader(guide: guide),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      value: '${guide.experienceYears}',
                      label: 'anos de\nexperiência',
                      icon: Icons.workspace_premium_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: '${guide.completedTrails}',
                      label: 'trilhas\nrealizadas',
                      icon: Icons.hiking_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: '${guide.totalKm.toStringAsFixed(0)} km',
                      label: 'quilômetros\nguiados',
                      icon: Icons.route_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Especialidades',
                style: TextStyle(
                  color: AppColors.green900,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: guide.specialties
                    .map(
                      (item) => Chip(
                        avatar: const Icon(
                          Icons.eco_outlined,
                          size: 16,
                          color: AppColors.green700,
                        ),
                        label: Text(item),
                        backgroundColor: AppColors.green100,
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              const Text(
                'Sobre o guia',
                style: TextStyle(
                  color: AppColors.green900,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                guide.bio,
                style: const TextStyle(
                  color: AppColors.ink,
                  height: 1.55,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: AppColors.cream,
                        appBar: AppBar(
                          title: Text(
                            'Mensagem para ${guide.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        body: MessagesScreen(
                          role: 'turista',
                          targetGuide: guide,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text('Conversar com ${guide.name.split(' ').first}'),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Trilhas deste guia',
                      style: TextStyle(
                        color: AppColors.green900,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${guideTrails.length}',
                    style: const TextStyle(
                      color: AppColors.green700,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (guideTrails.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Este guia ainda não possui trilhas publicadas no catálogo.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                ...guideTrails.map(
                  (trail) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GuideTrailCard(
                      trail: trail,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrailDetailsScreen(
                              trail: trail,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              const Text(
                'Avaliações',
                style: TextStyle(
                  color: AppColors.green900,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _ReviewCard(
                name: 'Mariana',
                text:
                    '${guide.name.split(' ').first} foi muito atencioso, explicou o percurso e manteve o grupo seguro durante toda a atividade.',
              ),
              const SizedBox(height: 8),
              _ReviewCard(
                name: 'João',
                text:
                    'Ótima experiência. Pontual, organizado e conhecia muito bem a região.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.guide});

  final GuideProfile guide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: NetworkImageBox(
              url: guide.imageUrl,
              borderRadius: 44,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        guide.name,
                        style: const TextStyle(
                          color: AppColors.green900,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (guide.verified) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.green700,
                        size: 19,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${guide.rating} (${guide.reviews} avaliações)',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.muted,
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      guide.location,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      height: 108,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.green700, size: 21),
          const SizedBox(height: 7),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.green900,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTrailCard extends StatelessWidget {
  const _GuideTrailCard({
    required this.trail,
    required this.onTap,
  });

  final Trail trail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 76,
                child: NetworkImageBox(
                  url: trail.imageUrl,
                  borderRadius: 12,
                ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trail.location,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${trail.difficulty} • ${trail.distanceKm} km • R\$ ${trail.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.green700,
                        fontSize: 10.5,
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.text,
  });

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Text(
                '★★★★★',
                style: TextStyle(
                  color: AppColors.gold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
