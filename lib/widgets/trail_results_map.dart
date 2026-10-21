import 'package:flutter/material.dart';
import 'dart:math' as math;
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

class TrailMapGroup {
  TrailMapGroup(this.position, this.trails);
  final LatLng position;
  final List<Trail> trails;
}

/// Agrupa marcadores que ocupariam a mesma área visual no zoom atual.
List<TrailMapGroup> groupTrailMarkers(List<Trail> trails, double zoom) {
  final groups = <TrailMapGroup>[];
  final worldSize = 256 * math.pow(2, zoom);
  Offset project(LatLng point) {
    final sinLatitude = math.sin(
      point.latitude.clamp(-85.0511, 85.0511) * math.pi / 180,
    );
    return Offset(
      (point.longitude + 180) / 360 * worldSize,
      (.5 - math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi)) *
          worldSize,
    );
  }

  for (final trail in trails) {
    final position = trailMapPosition(trail);
    if (position == null) continue;
    final pixel = project(position);
    final group = groups.where((group) {
      final other = project(group.position);
      final dx = (pixel.dx - other.dx).abs();
      return math.sqrt(
            math.pow(math.min(dx, worldSize - dx), 2) +
                math.pow(pixel.dy - other.dy, 2),
          ) <
          60;
    }).firstOrNull;
    if (group == null) {
      groups.add(TrailMapGroup(position, [trail]));
    } else {
      group.trails.add(trail);
    }
  }
  return groups;
}

class TrailResultsMap extends StatefulWidget {
  const TrailResultsMap({
    super.key,
    required this.trails,
    required this.onSelected,
    this.selectedId,
    this.tileProvider,
    this.height = 340,
  });

  final List<Trail> trails;
  final ValueChanged<Trail> onSelected;
  final String? selectedId;
  final TileProvider? tileProvider;
  final double height;

  @override
  State<TrailResultsMap> createState() => _TrailResultsMapState();
}

class _TrailResultsMapState extends State<TrailResultsMap> {
  bool tileError = false;

  Future<void> _openGroup(TrailMapGroup group) async {
    if (group.trails.length == 1) {
      widget.onSelected(group.trails.single);
      return;
    }
    final selected = await showModalBottomSheet<Trail>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .6,
        child: Column(
          children: [
            ListTile(
              title: Text('${group.trails.length} roteiros nesta região'),
              trailing: IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: group.trails.length,
                itemBuilder: (context, index) {
                  final trail = group.trails[index];
                  return ListTile(
                    title: Text(trail.name),
                    subtitle: Text(
                      '${trail.responsibleName} • ${trail.distanceLabel}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, trail),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) widget.onSelected(selected);
  }

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
            'Os roteiros encontrados não possuem coordenadas válidas. Consulte a lista de resultados.',
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
            height: widget.height,
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
                Builder(
                  builder: (context) {
                    final groups = groupTrailMarkers(
                      mapped,
                      MapCamera.of(context).zoom,
                    );
                    return MarkerLayer(
                      markers: groups
                          .map(
                            (group) => Marker(
                              point: group.position,
                              width: 52,
                              height: 52,
                              child: Tooltip(
                                message: group.trails.length == 1
                                    ? 'Abrir roteiro: ${group.trails.single.name}'
                                    : '${group.trails.length} roteiros nesta região',
                                child: IconButton(
                                  onPressed: () => _openGroup(group),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        group.trails.any(
                                          (trail) =>
                                              widget.selectedId == trail.id,
                                        )
                                        ? AppColors.earth
                                        : AppColors.forest,
                                    foregroundColor: AppColors.white,
                                  ),
                                  icon: group.trails.length == 1
                                      ? const Icon(Icons.terrain)
                                      : Text(
                                          '${group.trails.length}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
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
          '${mapped.length} roteiro(s) no mapa. Toque em um marcador para abrir os detalhes.',
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
