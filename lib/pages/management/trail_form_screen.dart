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

  String difficulty = 'Moderada';
  String modality = 'Trekking';
  String? guideName;
  String? guideId;
  DateTime? date;
  Uint8List? imageBytes;
  String? existingImageUrl;
  double? latitude;
  double? longitude;
  bool locating = false;
  bool saving = false;
  bool accessible = false;
  final List<TrailPoint> routePoints = [];
  TimeOfDay? startTime;
  TimeOfDay? endTime;

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
      difficulty = trail.difficulty;
      modality = trail.modality;
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
      date = _parseDate(trail.date);
      accessible = trail.accessible;
      recommendedItemsController.text = trail.recommendedItems.join(', ');
      routePoints.addAll(trail.route);
      capacityController.text = trail.capacity.toString();
      startTime = _parseTime(trail.startTime);
      endTime = _parseTime(trail.endTime);
    }
  }

  DateTime? _parseDate(String value) {
    final short = value.split(' ').first;

    if (short.contains('-')) {
      return DateTime.tryParse(short);
    }

    final parts = short.split('/');
    if (parts.length != 3) return null;

    return DateTime.tryParse(
      '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
    );
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeValue(TimeOfDay? value) => value == null
      ? ''
      : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool start}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start
          ? startTime ?? const TimeOfDay(hour: 8, minute: 0)
          : endTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        startTime = selected;
      } else {
        endTime = selected;
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

  Future<void> _pickDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: date ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2035),
    );

    if (selected != null) {
      setState(() => date = selected);
    }
  }

  String get dateLabel {
    if (date == null) return 'Selecionar data';

    final day = date!.day.toString().padLeft(2, '0');
    final month = date!.month.toString().padLeft(2, '0');

    return '$day/$month/${date!.year}';
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
    if ((startTime == null) != (endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe horário inicial e final.')),
      );
      return;
    }
    if (startTime != null && endTime != null) {
      final startMinutes = startTime!.hour * 60 + startTime!.minute;
      final endMinutes = endTime!.hour * 60 + endTime!.minute;
      if (startMinutes >= endMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O horário final deve ser posterior ao inicial.'),
          ),
        );
        return;
      }
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
      date: dateLabel,
      price: price,
      status: current?.status ?? 'Ativa',
      modality: modality,
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
      startTime: _timeValue(startTime),
      endTime: _timeValue(endTime),
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
              ? 'Trilha adicionada com sucesso.'
              : 'Trilha atualizada com sucesso.',
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
          widget.existing == null ? 'Nova trilha' : 'Editar trilha',
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
                'Apresente sua trilha',
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
                                'Adicionar foto da trilha',
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
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(start: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Início',
                          prefixIcon: Icon(Icons.schedule_outlined),
                        ),
                        child: Text(
                          startTime == null
                              ? 'Selecionar'
                              : startTime!.format(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(start: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fim'),
                        child: Text(
                          endTime == null
                              ? 'Selecionar'
                              : endTime!.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
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
                items: const [
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
              DropdownButtonFormField<String>(
                initialValue: modality,
                decoration: const InputDecoration(labelText: 'Modalidade'),
                items: const [
                  DropdownMenuItem(value: 'Trekking', child: Text('Trekking')),
                  DropdownMenuItem(value: 'Hiking', child: Text('Hiking')),
                  DropdownMenuItem(
                    value: 'Caminhada',
                    child: Text('Caminhada'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => modality = value);
                  }
                },
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
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data da atividade',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(dateLabel),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Trilha acessível'),
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
                  ? 'Adicionar trilha'
                  : 'Salvar alterações',
            ),
          ),
        ),
      ),
    );
  }
}
