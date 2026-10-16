import 'dart:async';
import 'package:flutter_map/flutter_map.dart' show TileProvider;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/trail_results_map.dart';
import 'trail_details_screen.dart';

class TrailSearchScreen extends StatefulWidget {
  const TrailSearchScreen({super.key, this.tileProvider});
  final TileProvider? tileProvider;

  @override
  State<TrailSearchScreen> createState() => _TrailSearchScreenState();
}

class _TrailSearchScreenState extends State<TrailSearchScreen> {
  final city = TextEditingController();
  final state = TextEditingController();

  String difficulty = 'Todas';
  String modality = 'Todas';
  DateTime? startDate;
  DateTime? endDate;
  bool nearMe = false;
  bool accessibleOnly = false;
  double radiusKm = 20;
  Position? position;
  bool locating = false;
  bool showMap = true;
  String? selectedTrailId;

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
        throw StateError(
          'Permita o acesso à localização nas configurações do navegador ou dispositivo e tente novamente. Você também pode buscar por cidade e UF.',
        );
      }

      final current = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 15),
      );

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : error is PermissionDeniedException
                ? 'Permita o acesso à localização nas configurações do navegador ou dispositivo. Você também pode buscar por cidade e UF.'
                : error is TimeoutException
                ? 'Não foi possível obter sua localização a tempo. Tente novamente ou busque por cidade e UF.'
                : 'Não foi possível obter sua localização. Verifique a permissão e tente novamente, ou busque por cidade e UF.',
          ),
        ),
      );
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

    if (!nearMe || current == null || trailMapPosition(trail) == null) {
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

      final modalityMatch = _matchesModality(trail);

      final date = _trailDate(trail);

      final startMatch =
          startDate == null || (date != null && !date.isBefore(startDate!));

      final endMatch =
          endDate == null || (date != null && !date.isAfter(endDate!));

      final distance = _distanceFromUser(trail);

      final nearMatch = !nearMe || (distance != null && distance <= radiusKm);
      final accessibilityMatch = !accessibleOnly || trail.accessible;

      if (cityMatch &&
          stateMatch &&
          difficultyMatch &&
          modalityMatch &&
          startMatch &&
          endMatch &&
          nearMatch &&
          accessibilityMatch) {
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

  bool _matchesModality(Trail trail) {
    if (modality == 'Todas') return true;
    final values = trail.effectiveActivities
        .map((activity) => activity.toLowerCase())
        .toList();
    final terms = switch (modality) {
      'Trilha' => const ['trilha', 'trekking', 'caminhada'],
      'Aquatrekking' => const ['aquatrekking', 'aqua trekking'],
      'Acampamento' => const ['acampamento', 'camping'],
      'Rapel' => const ['rapel'],
      'Tirolesa' => const ['tirolesa'],
      'Escalada' => const ['escalada'],
      'Ciclismo' => const ['ciclismo', 'bike', 'cicloturismo'],
      _ => [modality.toLowerCase()],
    };
    return values.any((value) => terms.any(value.contains));
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        startDate = date;
        if (endDate != null && endDate!.isBefore(date)) endDate = null;
      });
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
      modality = 'Todas';
      startDate = null;
      endDate = null;
      nearMe = false;
      accessibleOnly = false;
      position = null;
      radiusKm = 20;
      selectedTrailId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 12),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar roteiros',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Destino · data · dificuldade',
                      style: TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                key: ValueKey('modalidade-$modality'),
                initialValue: modality,
                decoration: const InputDecoration(
                  labelText: 'Atividade do roteiro',
                  prefixIcon: Icon(Icons.hiking_rounded),
                ),
                items: [
                  const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                  ...RouteActivity.values.map(
                    (activity) => DropdownMenuItem(
                      value: activity,
                      child: Text(activity),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => modality = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(difficulty),
                initialValue: difficulty,
                decoration: const InputDecoration(labelText: 'Dificuldade'),
                items: [
                  const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                  ...TrailDifficulty.values.map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  ),
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
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  locating
                      ? 'Obtendo GPS...'
                      : nearMe
                      ? 'Localização capturada.'
                      : 'Usa o GPS do dispositivo.',
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: accessibleOnly,
                onChanged: (value) => setState(() => accessibleOnly = value),
                title: const Text(
                  'Somente roteiros acessíveis',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Mostra percursos informados como acessíveis pelo responsável.',
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
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (results.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => showMap = !showMap),
                        icon: Icon(showMap ? Icons.list : Icons.map_outlined),
                        label: Text(showMap ? 'Ocultar mapa' : 'Mostrar mapa'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (showMap) ...[
                  TrailResultsMap(
                    trails: results.map((r) => r.trail).toList(),
                    selectedId: selectedTrailId,
                    tileProvider: widget.tileProvider,
                    onSelected: (trail) {
                      setState(() => selectedTrailId = trail.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrailDetailsScreen(trail: trail),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ],
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Nenhum roteiro encontrado com esses filtros.'),
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
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: AppColors.shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TrailDetailsScreen(trail: trail)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 116,
                height: 96,
                child: NetworkImageBox(url: trail.imageUrl, borderRadius: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trail.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trail.location,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${trail.difficulty} · ${trail.distanceLabel}',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (result.userDistanceKm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${result.userDistanceKm!.toStringAsFixed(1)} km de você',
                        style: const TextStyle(
                          color: AppColors.green900,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
