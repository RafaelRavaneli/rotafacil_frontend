import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/trail.dart';
import '../theme/app_colors.dart';
import 'trail_results_map.dart' show trailMapPosition;

class TrailLocationMap extends StatefulWidget {
  const TrailLocationMap({super.key, required this.trail, this.tileProvider});

  final Trail trail;
  final TileProvider? tileProvider;

  @override
  State<TrailLocationMap> createState() => _TrailLocationMapState();
}

class _TrailLocationMapState extends State<TrailLocationMap> {
  bool tileError = false;

  Future<void> _openGoogleMaps(LatLng destination) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destination.latitude},${destination.longitude}',
      'travelmode': 'driving',
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = trailMapPosition(widget.trail);
    if (destination == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Localização da atividade',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 260,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: destination,
                initialZoom: 14,
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
                  markers: [
                    Marker(
                      point: destination,
                      width: 54,
                      height: 54,
                      child: const CircleAvatar(
                        backgroundColor: AppColors.forest,
                        child: Icon(
                          Icons.location_on_rounded,
                          color: AppColors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
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
        const SizedBox(height: 10),
        Text(
          widget.trail.location,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${destination.latitude.toStringAsFixed(5)}, '
          '${destination.longitude.toStringAsFixed(5)}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        if (tileError) ...[
          const SizedBox(height: 6),
          const Text(
            'Não foi possível carregar parte do mapa.',
            style: TextStyle(color: AppColors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _openGoogleMaps(destination),
          icon: const Icon(Icons.directions_rounded),
          label: const Text('Abrir rota no Google Maps'),
        ),
      ],
    );
  }
}
