import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/trail.dart';
import '../theme/app_colors.dart';

/// A missing or invalid coordinate never receives a fabricated map position.
LatLng? trailMapPosition(Trail trail) {
  final latitude = trail.latitude;
  final longitude = trail.longitude;
  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180) {
    return null;
  }
  return LatLng(latitude, longitude);
}

class TrailResultsMap extends StatefulWidget {
  const TrailResultsMap({
    super.key,
    required this.trails,
    required this.onSelected,
    this.selectedId,
    this.tileProvider,
  });

  final List<Trail> trails;
  final ValueChanged<Trail> onSelected;
  final String? selectedId;
  final TileProvider? tileProvider;

  @override
  State<TrailResultsMap> createState() => _TrailResultsMapState();
}

class _TrailResultsMapState extends State<TrailResultsMap> {
  bool tileError = false;

  @override
  Widget build(BuildContext context) {
    final mapped = widget.trails
        .where((t) => trailMapPosition(t) != null)
        .toList();
    if (mapped.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'As trilhas encontradas não possuem coordenadas válidas. Consulte a lista de resultados.',
          ),
        ),
      );
    }
    final points = mapped.map((t) => trailMapPosition(t)!).toList();
    final uniquePoints = points
        .map((p) => '${p.latitude},${p.longitude}')
        .toSet();
    final signature = mapped
        .map((t) => '${t.id}:${t.latitude}:${t.longitude}')
        .join('|');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 340,
            child: FlutterMap(
              key: ValueKey(signature),
              options: MapOptions(
                initialCenter: points.first,
                initialZoom: 12,
                initialCameraFit: uniquePoints.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(48),
                        maxZoom: 14,
                      )
                    : null,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  tileProvider: widget.tileProvider,
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.rotafacil.app',
                  errorTileCallback: (_, _, _) {
                    if (!tileError && mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => tileError = true);
                      });
                    }
                  },
                ),
                MarkerLayer(
                  markers: mapped
                      .map(
                        (trail) => Marker(
                          point: trailMapPosition(trail)!,
                          width: 52,
                          height: 52,
                          child: Tooltip(
                            message: 'Abrir trilha: ${trail.name}',
                            child: IconButton(
                              onPressed: () => widget.onSelected(trail),
                              style: IconButton.styleFrom(
                                backgroundColor: widget.selectedId == trail.id
                                    ? AppColors.earth
                                    : AppColors.forest,
                                foregroundColor: AppColors.white,
                              ),
                              icon: const Icon(Icons.terrain),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${mapped.length} trilha(s) no mapa. Toque em um marcador para abrir os detalhes.',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        if (mapped.length < widget.trails.length)
          Text(
            '${widget.trails.length - mapped.length} resultado(s) sem coordenadas válidas continuam na lista.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        if (tileError)
          const Text(
            'Não foi possível carregar parte do mapa. Consulte a lista abaixo.',
            style: TextStyle(color: AppColors.red, fontSize: 12),
          ),
      ],
    );
  }
}
