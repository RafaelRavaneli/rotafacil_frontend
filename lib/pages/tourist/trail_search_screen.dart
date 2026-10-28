import '../../services/location_service.dart';
import '../../services/trail_search_service.dart';
import '../../models/trail_accessibility.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/brazil_location_fields.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart' show TileProvider;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/trail_results_map.dart';
import '../../navigation/app_routes.dart';
import 'trail_details_screen.dart';

class TrailSearchScreen extends StatefulWidget {
  const TrailSearchScreen({super.key, this.tileProvider, this.searchService});
  final TileProvider? tileProvider;
  final TrailSearchService? searchService;

  @override
  State<TrailSearchScreen> createState() => _TrailSearchScreenState();
}

class _TrailSearchScreenState extends State<TrailSearchScreen>
    with WidgetsBindingObserver {
  final city = TextEditingController();
  final state = TextEditingController();
  final _scrollController = ScrollController();
  bool? _mobileFiltersExpanded;
  // Celular: false = tela de filtros; true = mapa com a lista que sobe.
  bool _mobileResults = false;
  bool _sheetOpen = false;
  final _sheetController = DraggableScrollableController();

  String difficulty = 'Todas';
  String modality = 'Todas';
  DateTime? startDate;
  DateTime? endDate;
  bool nearMe = false;
  final Set<String> accessibilityResources = {};
  double radiusKm = 20;
  UserCoordinates? position;
  bool locating = false;
  bool showMap = true;
  String? selectedTrailId;
  late final _search = widget.searchService ?? TrailSearchService();
  Timer? _debounce;
  String? _queryKey;
  int _generation = 0;
  bool _loading = false;
  String? _searchError;
  TrailSearchPage? _page;
  final List<_TrailResult> _remote = [];

  Map<String, String> get _filters => {
    if (city.text.trim().isNotEmpty) 'cidade': city.text.trim(),
    if (state.text.trim().isNotEmpty) 'estado': state.text.trim(),
    if (difficulty != 'Todas') 'dificuldade': difficulty,
    if (modality != 'Todas') 'modalidade': modality,
    if (startDate != null)
      'data_inicio': startDate!.toIso8601String().split('T').first,
    if (endDate != null)
      'data_fim': endDate!.toIso8601String().split('T').first,
    if (accessibilityResources.isNotEmpty)
      'recursos_acessibilidade': (accessibilityResources.toList()..sort()).join(
        ',',
      ),
    if (nearMe && position != null) ...{
      'latitude': '${position!.latitude}',
      'longitude': '${position!.longitude}',
      'raio_km': '$radiusKm',
    },
  };

  void _syncSearch() {
    if (!AppStore.instance.useBackend) return;
    final filters = _filters;
    final key = filters.toString();
    if (key == _queryKey) return;
    _queryKey = key;
    final generation = ++_generation;
    _debounce?.cancel();
    _remote.clear();
    _page = null;
    _loading = true;
    _searchError = null;
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => _loadRemote(filters, generation),
    );
  }

  Future<void> _loadRemote(
    Map<String, String> filters,
    int generation, {
    int page = 1,
  }) async {
    try {
      final result = await _search.search(filters, page: page);
      if (!mounted || generation != _generation) return;
      setState(() {
        _searchError = null;
        _page = result;
        final ids = _remote.map((r) => r.trail.id).toSet();
        _remote.addAll(
          result.items
              .where((r) => ids.add(r.trail.id))
              .map(
                (r) =>
                    _TrailResult(trail: r.trail, userDistanceKm: r.distanceKm),
              ),
        );
        _loading = false;
        _mobileFiltersExpanded ??= false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _searchError = 'Não foi possível atualizar a busca. Tente novamente.';
      });
    }
  }

  void _retrySearch() {
    setState(() {
      ++_generation;
      _queryKey = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppStore.instance.addListener(_retrySearch);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState value) {
    if (value == AppLifecycleState.resumed) _retrySearch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppStore.instance.removeListener(_retrySearch);
    _debounce?.cancel();
    city.dispose();
    state.dispose();
    _scrollController.dispose();
    _sheetController.dispose();
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
      final current = await LocationService.instance.capture();

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
      final accessibilityMatch = trail.accessibility.matches(
        accessibilityResources,
      );

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

  bool get _filtersExpanded =>
      _mobileFiltersExpanded ??
      (AppStore.instance.useBackend ? _page == null : filtered.isEmpty);

  String get _filterSummary {
    final parts = <String>[
      if (city.text.trim().isNotEmpty)
        city.text.trim()
      else if (state.text.trim().isNotEmpty)
        state.text.trim(),
      if (modality != 'Todas') modality,
      if (difficulty != 'Todas') difficulty,
      if (startDate != null || endDate != null)
        '${_dateLabel(startDate)} a ${_dateLabel(endDate)}',
      if (nearMe) 'Até ${radiusKm.round()} km de você',
      if (accessibilityResources.isNotEmpty)
        '${accessibilityResources.length} recurso(s) de acessibilidade',
    ];
    return parts.isEmpty
        ? 'Destino, atividade, datas e mais opções'
        : parts.join(' · ');
  }

  void _setFiltersExpanded(bool expanded) {
    if (!expanded) FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _mobileFiltersExpanded = expanded);
    if (!expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        unawaited(
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          ),
        );
      });
    }
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
      accessibilityResources.clear();
      position = null;
      radiusKm = 20;
      selectedTrailId = null;
      _mobileFiltersExpanded = true;
    });
  }

  List<Widget> _filterFields({required bool collapsible}) => [
    BrazilLocationFields(
      city: city,
      state: state,
      onChanged: () => setState(() {}),
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      key: ValueKey('modalidade-$modality'),
      initialValue: modality,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Atividade do roteiro',
        prefixIcon: Icon(Icons.hiking_rounded),
      ),
      items: [
        const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
        ...RouteActivity.values.map(
          (activity) =>
              DropdownMenuItem(value: activity, child: Text(activity)),
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
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Dificuldade'),
      items: [
        const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
        ...TrailDifficulty.values.map(
          (value) => DropdownMenuItem(value: value, child: Text(value)),
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
    ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Recursos de acessibilidade'),
      subtitle: Text(
        accessibilityResources.isEmpty
            ? 'Nenhum recurso selecionado'
            : '${accessibilityResources.length} recurso(s) selecionado(s)',
      ),
      children: [
        const Text(
          'Exibe somente roteiros com todos os recursos selecionados confirmados pelo responsável.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in TrailAccessibility.filterKeys)
              FilterChip(
                label: Text(TrailAccessibility.labels[key]!),
                selected: accessibilityResources.contains(key),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    accessibilityResources.add(key);
                  } else {
                    accessibilityResources.remove(key);
                  }
                }),
              ),
          ],
        ),
      ],
    ),
    if (nearMe) ...[
      Row(
        children: [
          const Text('Raio', style: TextStyle(fontWeight: FontWeight.w800)),
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
    if (collapsible) ...[
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 8,
        children: [
          TextButton(onPressed: _clear, child: const Text('Limpar filtros')),
          FilledButton.icon(
            key: const ValueKey('search-show-results'),
            onPressed: () => _setFiltersExpanded(false),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Ver resultados'),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ],
  ];

  Widget _filterHeader(bool expanded) => Material(
    color: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      key: const ValueKey('search-filters-toggle'),
      leading: const Icon(Icons.tune_rounded),
      title: const Text(
        'Filtros de busca',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        _filterSummary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      onTap: () => _setFiltersExpanded(!expanded),
    ),
  );

  Widget _resultsMap(
    List<_TrailResult> results, {
    double height = 340,
    bool fill = false,
  }) {
    if (results.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum roteiro para exibir no mapa.'),
        ),
      );
    }
    return TrailResultsMap(
      key: const ValueKey('search-results-map'),
      trails: results.map((result) => result.trail).toList(),
      selectedId: selectedTrailId,
      tileProvider: widget.tileProvider,
      height: height,
      borderRadius: fill ? 0 : 22,
      showDetails: !fill,
      onSelected: (trail) {
        setState(() => selectedTrailId = trail.id);
        AppRoutes.push(
          context,
          AppRoutes.trail(trail.id),
          (_) => TrailDetailsScreen(trail: trail),
        );
      },
    );
  }

  List<Widget> _resultsHeader(List<_TrailResult> results, bool remote) => [
    Text(
      '${remote ? (_page?.total ?? 0) : results.length} resultado(s)',
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 10),
    if (results.isNotEmpty) ...[
      OutlinedButton.icon(
        onPressed: () => setState(() => showMap = !showMap),
        icon: Icon(showMap ? Icons.list : Icons.map_outlined),
        label: Text(showMap ? 'Ocultar mapa' : 'Mostrar mapa'),
      ),
      const SizedBox(height: 12),
    ],
  ];

  List<Widget> _resultCards(List<_TrailResult> results, bool remote) => [
    if (remote && _loading) const LinearProgressIndicator(),
    if (remote && _searchError != null) ...[
      Text(_searchError!),
      TextButton(
        onPressed: _retrySearch,
        child: const Text('Tentar novamente'),
      ),
    ],
    if (results.isEmpty && !_loading && _searchError == null)
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
    if (remote && _page?.nextPage != null)
      TextButton(
        onPressed: _loading
            ? null
            : () {
                setState(() => _loading = true);
                unawaited(
                  _loadRemote(_filters, _generation, page: _page!.nextPage!),
                );
              },
        child: const Text('Carregar mais roteiros'),
      ),
  ];


  // ------------------------------------------------------------------
  // Celular: filtros -> mapa com os pontos -> lista que sobe (Figma).
  // O conteúdo é o mesmo da busca original.
  // ------------------------------------------------------------------

  void _setMobileResults(bool value) {
    if (value) FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _mobileResults = value;
      _sheetOpen = false;
    });
  }

  Widget _sectionCard({String? title, required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        child,
      ],
    ),
  );

  Widget _difficultyChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final value in ['Todas', ...TrailDifficulty.values])
        ChoiceChip(
          key: ValueKey('dificuldade-$value'),
          label: Text(value),
          selected: difficulty == value,
          showCheckmark: false,
          backgroundColor: AppColors.paper,
          selectedColor: AppColors.leaf,
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          labelStyle: TextStyle(
            color: difficulty == value ? AppColors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => setState(() => difficulty = value),
        ),
    ],
  );

  Widget _dateField(
    String label,
    IconData icon,
    DateTime? value,
    VoidCallback onTap,
  ) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.leaf),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dateLabel(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _mobileFilters() => Column(
    children: [
      Expanded(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _sectionCard(
              title: 'Local',
              child: BrazilLocationFields(
                city: city,
                state: state,
                onChanged: () => setState(() {}),
              ),
            ),
            _sectionCard(
              child: DropdownButtonFormField<String>(
                key: ValueKey('modalidade-$modality'),
                initialValue: modality,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Atividade do roteiro',
                  prefixIcon: Icon(Icons.hiking_rounded),
                ),
                items: [
                  const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                  ...RouteActivity.values.map(
                    (activity) =>
                        DropdownMenuItem(value: activity, child: Text(activity)),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => modality = value);
                },
              ),
            ),
            _sectionCard(title: 'Dificuldade', child: _difficultyChips()),
            _sectionCard(
              title: 'Período',
              child: Row(
                children: [
                  _dateField(
                    'De',
                    Icons.calendar_today_outlined,
                    startDate,
                    _pickStart,
                  ),
                  const SizedBox(width: 12),
                  _dateField(
                    'Até',
                    Icons.event_available_outlined,
                    endDate,
                    _pickEnd,
                  ),
                ],
              ),
            ),
            _sectionCard(
              title: 'Distância',
              child: Column(
                children: [
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
                      onChanged: (value) => setState(() => radiusKm = value),
                    ),
                  ],
                ],
              ),
            ),
            _sectionCard(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                title: const Text('Recursos de acessibilidade'),
                subtitle: Text(
                  accessibilityResources.isEmpty
                      ? 'Nenhum recurso selecionado'
                      : '${accessibilityResources.length} recurso(s) selecionado(s)',
                ),
                children: [
                  const Text(
                    'Exibe somente roteiros com todos os recursos selecionados confirmados pelo responsável.',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in TrailAccessibility.filterKeys)
                        FilterChip(
                          label: Text(TrailAccessibility.labels[key]!),
                          selected: accessibilityResources.contains(key),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              accessibilityResources.add(key);
                            } else {
                              accessibilityResources.remove(key);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              OutlinedButton(
                onPressed: _clear,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Limpar filtros'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('search-show-results'),
                  onPressed: () => _setMobileResults(true),
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver resultados'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _mobileResultChips(List<_TrailResult> results) {
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text('Nenhum roteiro encontrado com esses filtros.'),
        ),
      );
    }
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: results.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final trail = results[index].trail;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => AppRoutes.push(
              context,
              AppRoutes.trail(trail.id),
              (_) => TrailDetailsScreen(trail: trail),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      trail.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    trail.distanceLabel,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _backToMap() {
    unawaited(
      _sheetController.animateTo(
        .26,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _mobileFilterCard() => Material(
    color: AppColors.paper,
    elevation: 2,
    shadowColor: AppColors.shadow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.leaf, size: 20),
              SizedBox(width: 8),
              Text(
                'Filtros de busca',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _filterSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey('search-filters-toggle'),
            onPressed: () => _setMobileResults(false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: const StadiumBorder(),
              side: const BorderSide(color: AppColors.leaf),
            ),
            child: const Text('Editar filtros'),
          ),
        ],
      ),
    ),
  );

  Widget _mobileResultsView(List<_TrailResult> results, bool remote) {
    final count = remote ? (_page?.total ?? 0) : results.length;
    return Stack(
      children: [
        Positioned.fill(
          child: showMap && results.isNotEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => _resultsMap(
                    results,
                    height: constraints.maxHeight,
                    fill: true,
                  ),
                )
              : ColoredBox(
                  color: AppColors.sage,
                  child: Center(
                    child: results.isEmpty
                        ? const Text('Nenhum roteiro para exibir no mapa.')
                        : null,
                  ),
                ),
        ),
        // Com a lista aberta (tela inteira) o cartão de filtros passa a fazer
        // parte dela, junto com a opção de voltar ao mapa.
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: _sheetOpen ? const SizedBox.shrink() : _mobileFilterCard(),
        ),
        Positioned.fill(
          key: const ValueKey('search-sheet'),
          child: NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              final open = notification.extent > .5;
              if (open != _sheetOpen) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && open != _sheetOpen) {
                    setState(() => _sheetOpen = open);
                  }
                });
              }
              return false;
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: .26,
              minChildSize: .26,
              maxChildSize: 1,
              snap: true,
              snapSizes: const [.26, 1],
              builder: (context, controller) => Container(
                decoration: BoxDecoration(
                  color: _sheetOpen ? AppColors.cream : AppColors.paper,
                  borderRadius: _sheetOpen
                      ? BorderRadius.zero
                      : const BorderRadius.vertical(top: Radius.circular(24)),
                  border: _sheetOpen ? null : Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.leaf,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_sheetOpen) ...[
                      _mobileFilterCard(),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const ValueKey('search-back-to-map'),
                        onPressed: _backToMap,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Voltar ao mapa'),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Row(
                      children: [
                        Text(
                          '$count resultado(s)',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _sheetOpen ? 'Puxe para fechar' : 'Puxe para ver',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_sheetOpen)
                      _mobileResultChips(results)
                    else ...[
                      if (results.isNotEmpty) ...[
                        OutlinedButton.icon(
                          onPressed: () => setState(() => showMap = !showMap),
                          icon: Icon(showMap ? Icons.list : Icons.map_outlined),
                          label: Text(showMap ? 'Ocultar mapa' : 'Mostrar mapa'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ..._resultCards(results, remote),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final collapsible = width < 600 || width >= 1000;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: const AppBackButton(),
        backgroundColor: AppColors.cream,
        title: const Text('Buscar roteiros'),
        actions: [
          if (width < 600)
            IconButton(
              tooltip: _mobileResults ? 'Editar filtros' : 'Recolher filtros',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _setMobileResults(!_mobileResults),
            )
          else if (collapsible)
            IconButton(
              tooltip: _filtersExpanded ? 'Recolher filtros' : 'Editar filtros',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _setFiltersExpanded(!_filtersExpanded),
            )
          else
            TextButton(onPressed: _clear, child: const Text('Limpar')),
        ],
      ),
      body: AnimatedBuilder(
        animation: AppStore.instance,
        builder: (context, _) {
          _syncSearch();
          final remote = AppStore.instance.useBackend;
          final results = remote ? _remote : filtered;
          if (width < 600) {
            return _mobileResults
                ? _mobileResultsView(results, remote)
                : _mobileFilters();
          }
          final expanded = !collapsible || _filtersExpanded;
          final panel = AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _filterFields(collapsible: true),
                  )
                : const SizedBox(width: double.infinity),
          );

          if (width >= 1000) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _filterHeader(expanded),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * .45,
                      ),
                      child: SingleChildScrollView(child: panel),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView(
                              key: const ValueKey('search-results-pane'),
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              children: [
                                ..._resultsHeader(results, remote),
                                ..._resultCards(results, remote),
                              ],
                            ),
                          ),
                          if (showMap) ...[
                            const SizedBox(width: 24),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, mapConstraints) =>
                                    SingleChildScrollView(
                                      key: const ValueKey('search-map-pane'),
                                      child: _resultsMap(
                                        results,
                                        height: (mapConstraints.maxHeight - 100)
                                            .clamp(160, 1000)
                                            .toDouble(),
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (collapsible) ...[
                _filterHeader(expanded),
                const SizedBox(height: 12),
                panel,
              ] else
                ..._filterFields(collapsible: false),
              ..._resultsHeader(results, remote),
              if (showMap && results.isNotEmpty) ...[
                _resultsMap(results),
                const SizedBox(height: 20),
              ],
              ..._resultCards(results, remote),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          AppRoutes.push(
            context,
            AppRoutes.trail(trail.id),
            (_) => TrailDetailsScreen(trail: trail),
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
                        fontWeight: FontWeight.w700,
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
                        '${result.userDistanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km de você',
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
