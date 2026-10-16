import '../../utils/auth_error_message.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/trail.dart';
import '../../utils/run_action.dart';
import '../../services/session_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';

class TrailFormScreen extends StatefulWidget {
  const TrailFormScreen({super.key, required this.isAgency, this.existing});

  final bool isAgency;
  final Trail? existing;

  @override
  State<TrailFormScreen> createState() => _TrailFormScreenState();
}

class _TrailFormScreenState extends State<TrailFormScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final distanceController = TextEditingController();
  final priceController = TextEditingController();
  final recommendedItemsController = TextEditingController();
  final capacityController = TextEditingController(text: '12');

  String difficulty = TrailDifficulty.intermediate;
  final Set<String> activities = {'Trilha'};
  String? guideName;
  String? guideId;
  DateTime? startDateTime;
  DateTime? endDateTime;
  Uint8List? imageBytes;
  String? existingImageUrl;
  double? latitude;
  double? longitude;
  bool locating = false;
  bool saving = false;
  bool accessible = false;
  final List<TrailPoint> routePoints = [];

  @override
  void initState() {
    super.initState();
    final trail = widget.existing;

    if (trail != null) {
      nameController.text = trail.name;
      descriptionController.text = trail.description;
      cityController.text = trail.city;
      stateController.text = trail.state;
      distanceController.text = trail.hasDistance
          ? trail.distanceKm.toString()
          : '';
      priceController.text = trail.price.toStringAsFixed(2);
      difficulty = TrailDifficulty.normalize(trail.difficulty);
      activities
        ..clear()
        ..addAll(trail.effectiveActivities);
      guideName = trail.guideName;
      guideId = trail.guideId.isEmpty ? null : trail.guideId;

      if (guideId == null && guideName != null) {
        for (final guide in AppStore.instance.agencyGuides) {
          if (guide.name == guideName) {
            guideId = guide.id;
            break;
          }
        }
      }
      existingImageUrl = trail.imageUrl;
      latitude = trail.latitude;
      longitude = trail.longitude;
      startDateTime = trail.startsAt;
      endDateTime = trail.endsAt;
      accessible = trail.accessible;
      recommendedItemsController.text = trail.recommendedItems.join(', ');
      routePoints.addAll(trail.route);
      capacityController.text = trail.capacity.toString();
    }
  }

  String _dateValue(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _timeValue(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDateTime({required bool start}) async {
    final now = DateTime.now();
    final rawCurrent = start
        ? startDateTime ?? now.add(const Duration(days: 1))
        : endDateTime ??
              (startDateTime ?? now.add(const Duration(days: 1))).add(
                const Duration(hours: 4),
              );
    final today = DateTime(now.year, now.month, now.day);
    final minimum = !start && startDateTime != null
        ? DateTime(
            startDateTime!.year,
            startDateTime!.month,
            startDateTime!.day,
          )
        : today;
    final current = rawCurrent.isBefore(minimum) ? minimum : rawCurrent;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: minimum,
      lastDate: DateTime(2035),
    );
    if (selectedDate == null || !mounted) return;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (selectedTime == null) return;
    final value = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    setState(() {
      if (start) {
        startDateTime = value;
        if (endDateTime != null && !endDateTime!.isAfter(value)) {
          endDateTime = value.add(const Duration(hours: 4));
        }
      } else {
        endDateTime = value;
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    cityController.dispose();
    stateController.dispose();
    distanceController.dispose();
    priceController.dispose();
    recommendedItemsController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  void _addRoutePoint() {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obtenha a localização antes de adicionar o ponto.'),
        ),
      );
      return;
    }
    setState(() {
      routePoints.add(TrailPoint(latitude: latitude!, longitude: longitude!));
    });
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 900,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      imageBytes = bytes;
    });
  }

  Future<void> _useCurrentLocation() async {
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
          'Permita o acesso à localização nas configurações do navegador ou dispositivo e tente novamente.',
        );
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  String _dateTimeLabel(DateTime? value) {
    if (value == null) return 'Selecionar data e hora';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year} às ${_timeValue(value)}';
  }

  Future<void> _save() async {
    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, descrição e cidade.')),
      );
      return;
    }

    final distance = Trail.parseDistance(distanceController.text);
    if (distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe uma distância do percurso válida, maior que zero, em quilômetros.',
          ),
        ),
      );
      return;
    }
    final capacity = int.tryParse(capacityController.text.trim());
    if (capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma capacidade maior que zero.')),
      );
      return;
    }
    if (startDateTime == null || endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe início e fim do roteiro.')),
      );
      return;
    }
    if (!endDateTime!.isAfter(startDateTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O fim deve ser posterior ao início do roteiro.'),
        ),
      );
      return;
    }
    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma atividade.')),
      );
      return;
    }
    setState(() => saving = true);

    final price =
        double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;

    String imageUrl =
        existingImageUrl ??
        'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1200&q=80';

    if (imageBytes != null) {
      imageUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes!)}';
    }

    final current = widget.existing;

    final trail = Trail(
      id: current?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim().toUpperCase(),
      difficulty: difficulty,
      distanceKm: distance,
      duration: current?.duration ?? '3h',
      elevation: current?.elevation ?? 0,
      bestSeason: current?.bestSeason ?? 'Ano todo',
      rating: current?.rating ?? 0,
      reviews: current?.reviews ?? 0,
      description: descriptionController.text.trim(),
      imageUrl: imageUrl,
      guideName:
          guideName ??
          AppStore.instance
              .userForRole(SessionService.instance.role ?? 'guia')
              .name,
      guideId:
          guideId ??
          current?.guideId ??
          (AppStore.instance.useBackend
              ? SessionService.instance.userId ?? ''
              : ''),
      date: _dateValue(startDateTime!),
      price: price,
      status: current?.status ?? 'Ativa',
      modality: activities.first,
      activities: activities.toList(),
      latitude: latitude,
      longitude: longitude,
      accessible: accessible,
      recommendedItems: recommendedItemsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      route: List<TrailPoint>.from(routePoints),
      capacity: capacity,
      startTime: _timeValue(startDateTime!),
      endTime: _timeValue(endDateTime!),
      endDate: _dateValue(endDateTime!),
      startDateTime: startDateTime!.toIso8601String(),
      endDateTime: endDateTime!.toIso8601String(),
    );

    final saved = await runAction(context, () async {
      if (current == null) {
        await AppStore.instance.addTrail(trail);
      } else {
        await AppStore.instance.updateTrail(trail);
      }
    });
    if (mounted) setState(() => saving = false);
    if (!saved) return;

    if (!mounted) return;

    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          current == null
              ? 'Roteiro adicionado com sucesso.'
              : 'Roteiro atualizado com sucesso.',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final guides = AppStore.instance.agencyGuides;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Novo roteiro' : 'Editar roteiro',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              const Text(
                'Apresente seu roteiro',
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Foto, descrição e informações para ajudar o turista a escolher.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 190,
                  child: imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : existingImageUrl != null
                      ? NetworkImageBox(
                          url: existingImageUrl!,
                          borderRadius: 18,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.green100,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.green700,
                                size: 38,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Adicionar foto do roteiro',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Escolher da galeria',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Escolher/trocar foto'),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de vagas',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickDateTime(start: true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Início do roteiro',
                    prefixIcon: Icon(Icons.event_available_outlined),
                  ),
                  child: Text(_dateTimeLabel(startDateTime)),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickDateTime(start: false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fim do roteiro',
                    prefixIcon: Icon(Icons.event_busy_outlined),
                  ),
                  child: Text(_dateTimeLabel(endDateTime)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: stateController,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
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
                items: TrailDifficulty.values
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => difficulty = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Atividades do roteiro',
                  helperText: 'Selecione todas as atividades incluídas.',
                  alignLabelWithHint: true,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: RouteActivity.values
                      .map(
                        (activity) => FilterChip(
                          label: Text(activity),
                          selected: activities.contains(activity),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              activities.add(activity);
                            } else {
                              activities.remove(activity);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Informações da atividade',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: distanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Distância do percurso (km)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor por pessoa (R\$)',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Roteiro acessível'),
                subtitle: const Text(
                  'Informe se o percurso possui condições de acessibilidade.',
                ),
                value: accessible,
                onChanged: (value) => setState(() => accessible = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recommendedItemsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Itens recomendados',
                  hintText: 'Água, protetor solar, calçado adequado',
                  helperText: 'Separe os itens por vírgulas.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.green700,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            latitude == null || longitude == null
                                ? 'Nenhuma coordenada selecionada.'
                                : 'Latitude ${latitude!.toStringAsFixed(5)} • Longitude ${longitude!.toStringAsFixed(5)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: locating ? null : _useCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded),
                      label: Text(
                        locating
                            ? 'Obtendo localização...'
                            : 'Usar localização atual',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addRoutePoint,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Adicionar ponto ao percurso'),
                    ),
                    if (routePoints.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...routePoints.asMap().entries.map(
                        (entry) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.route_outlined),
                          title: Text('Ponto ${entry.key + 1}'),
                          subtitle: Text(
                            '${entry.value.latitude.toStringAsFixed(5)}, ${entry.value.longitude.toStringAsFixed(5)}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Remover ponto',
                            onPressed: () =>
                                setState(() => routePoints.removeAt(entry.key)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.isAgency) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: guides.any((guide) => guide.id == guideId)
                      ? guideId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Guia responsável',
                  ),
                  items: guides
                      .map(
                        (guide) => DropdownMenuItem(
                          value: guide.id,
                          child: Text(guide.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    String? selectedGuideName;

                    if (value != null) {
                      for (final guide in guides) {
                        if (guide.id == value) {
                          selectedGuideName = guide.name;
                          break;
                        }
                      }
                    }

                    setState(() {
                      guideName = selectedGuideName;
                      guideId = value;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: FilledButton(
            onPressed: saving ? null : _save,
            child: Text(
              saving
                  ? 'Salvando...'
                  : widget.existing == null
                  ? 'Adicionar roteiro'
                  : 'Salvar alterações',
            ),
          ),
        ),
      ),
    );
  }
}
