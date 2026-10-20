import 'package:flutter/material.dart';

import '../models/trail.dart';
import '../models/trail_experience.dart';
import '../state/app_store.dart';
import '../utils/date_time_format.dart';

class TrailWeatherCard extends StatefulWidget {
  const TrailWeatherCard({super.key, required this.trail, required this.date});

  final Trail trail;
  final DateTime? date;

  @override
  State<TrailWeatherCard> createState() => _TrailWeatherCardState();
}

class _TrailWeatherCardState extends State<TrailWeatherCard> {
  late Future<TrailWeather?> forecast;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TrailWeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trail.id != widget.trail.id ||
        oldWidget.date != widget.date ||
        oldWidget.trail.latitude != widget.trail.latitude ||
        oldWidget.trail.longitude != widget.trail.longitude) {
      _load();
    }
  }

  void _load() {
    forecast =
        widget.date == null ||
            widget.trail.latitude == null ||
            widget.trail.longitude == null
        ? Future.value(null)
        : AppStore.instance.weatherFor(widget.trail.id, date: widget.date);
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Previsão do tempo${widget.date == null ? '' : ' • ${formatBrazilianDate(widget.date!.toIso8601String())}'}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          FutureBuilder<TrailWeather?>(
            future: forecast,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return TextButton.icon(
                  onPressed: () => setState(_load),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Não foi possível carregar. Tentar novamente',
                  ),
                );
              }
              final weather = snapshot.data;
              if (weather == null) {
                return Text(
                  widget.date == null
                      ? 'Data da atividade não informada.'
                      : widget.trail.latitude == null ||
                            widget.trail.longitude == null
                      ? 'Localização do roteiro não informada.'
                      : 'Previsão indisponível para esta data. Consulte novamente quando estiver mais próxima; a previsão abrange até 16 dias.',
                );
              }
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_outlined),
                title: Text(weather.condition),
                subtitle: Text(
                  '${weather.minimumTemperature?.toStringAsFixed(0) ?? '-'} °C a '
                  '${weather.maximumTemperature?.toStringAsFixed(0) ?? '-'} °C • '
                  '${weather.rainProbability?.toString() ?? '-'}% de chuva',
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
