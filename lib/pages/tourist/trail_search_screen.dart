import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import 'trail_details_screen.dart';

class TrailSearchScreen extends StatefulWidget {
  const TrailSearchScreen({super.key});

  @override
  State<TrailSearchScreen> createState() => _TrailSearchScreenState();
}

class _TrailSearchScreenState extends State<TrailSearchScreen> {
  final city = TextEditingController();
  final state = TextEditingController();

  String difficulty = 'Todas';
  DateTime? startDate;
  DateTime? endDate;
  bool nearMe = false;
  double radiusKm = 20;
  Position? position;
  bool locating = false;

  @override
  void dispose() {
    city.dispose();
    state.dispose();
    super.dispose();
  }

  Future<void> _toggleNearMe(bool value) async {
    if (!value) {
      setState(() {
        nearMe = false;
        position = null;
      });
      return;
    }

    setState(() => locating = true);

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw StateError('Ative a localização do dispositivo.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Permissão de localização negada.');
      }

      final current = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        position = current;
        nearMe = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        nearMe = false;
        position = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  DateTime? _trailDate(Trail trail) {
    final value = trail.date.split(' ').first;

    if (value.contains('-')) {
      return DateTime.tryParse(value);
    }

    final parts = value.split('/');
    if (parts.length != 3) return null;

    return DateTime.tryParse(
      '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
    );
  }

  double? _distanceFromUser(Trail trail) {
    final current = position;

    if (!nearMe ||
        current == null ||
        trail.latitude == null ||
        trail.longitude == null) {
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

  List<_TrailResult> get filtered {
    final cityTerm = city.text.trim().toLowerCase();
    final stateTerm = state.text.trim().toLowerCase();

    final results = <_TrailResult>[];

    for (final trail in AppStore.instance.trails) {
      if (!TrailStatus.isActive(trail.status)) continue;
      final cityMatch =
          cityTerm.isEmpty || trail.city.toLowerCase().contains(cityTerm);

      final stateMatch =
          stateTerm.isEmpty || trail.state.toLowerCase() == stateTerm;

      final difficultyMatch =
          difficulty == 'Todas' ||
          trail.difficulty.toLowerCase() == difficulty.toLowerCase();

      final date = _trailDate(trail);

      final startMatch =
          startDate == null || date == null || !date.isBefore(startDate!);

      final endMatch =
          endDate == null || date == null || !date.isAfter(endDate!);

      final distance = _distanceFromUser(trail);

      final nearMatch = !nearMe || (distance != null && distance <= radiusKm);

      if (cityMatch &&
          stateMatch &&
          difficultyMatch &&
          startMatch &&
          endMatch &&
          nearMatch) {
        results.add(_TrailResult(trail: trail, userDistanceKm: distance));
      }
    }

    if (nearMe) {
      results.sort(
        (a, b) =>
            (a.userDistanceKm ?? 999999).compareTo(b.userDistanceKm ?? 999999),
      );
    }

    return results;
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() => startDate = date);
    }
  }

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() => endDate = date);
    }
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Qualquer';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _clear() {
    city.clear();
    state.clear();

    setState(() {
      difficulty = 'Todas';
      startDate = null;
      endDate = null;
      nearMe = false;
      position = null;
      radiusKm = 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buscar trilhas',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [TextButton(onPressed: _clear, child: const Text('Limpar'))],
      ),
      body: AnimatedBuilder(
        animation: AppStore.instance,
        builder: (context, _) {
          final results = filtered;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: city,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Cidade',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: state,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: difficulty,
                decoration: const InputDecoration(labelText: 'Dificuldade'),
                items: const [
                  DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                  DropdownMenuItem(value: 'Fácil', child: Text('Fácil')),
                  DropdownMenuItem(value: 'Moderada', child: Text('Moderada')),
                  DropdownMenuItem(value: 'Difícil', child: Text('Difícil')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => difficulty = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('De: ${_dateLabel(startDate)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEnd,
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text('Até: ${_dateLabel(endDate)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: nearMe,
                onChanged: locating ? null : _toggleNearMe,
                title: const Text(
                  'Buscar perto de mim',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  locating
                      ? 'Obtendo GPS...'
                      : nearMe
                      ? 'Localização capturada.'
                      : 'Usa o GPS do dispositivo.',
                ),
              ),
              if (nearMe) ...[
                Row(
                  children: [
                    const Text(
                      'Raio',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      '${radiusKm.round()} km',
                      style: const TextStyle(
                        color: AppColors.green700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Slider(
                  min: 5,
                  max: 100,
                  divisions: 19,
                  value: radiusKm,
                  activeColor: AppColors.green700,
                  onChanged: (value) {
                    setState(() => radiusKm = value);
                  },
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '${results.length} resultado(s)',
                style: const TextStyle(
                  color: AppColors.green900,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Nenhuma trilha encontrada com esses filtros.'),
                  ),
                )
              else
                ...results.map(
                  (result) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResultCard(result: result),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TrailResult {
  const _TrailResult({required this.trail, this.userDistanceKm});

  final Trail trail;
  final double? userDistanceKm;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final _TrailResult result;

  @override
  Widget build(BuildContext context) {
    final trail = result.trail;

    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TrailDetailsScreen(trail: trail)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 78,
                child: NetworkImageBox(url: trail.imageUrl, borderRadius: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trail.name,
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
                      '${trail.difficulty} • ${trail.distanceKm} km • ★ ${trail.rating}',
                      style: const TextStyle(
                        color: AppColors.green700,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (result.userDistanceKm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${result.userDistanceKm!.toStringAsFixed(1)} km de você',
                        style: const TextStyle(
                          color: AppColors.green900,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
