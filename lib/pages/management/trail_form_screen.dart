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

  @override
  void initState() {
    super.initState();
    final trail = widget.existing;

    if (trail != null) {
      nameController.text = trail.name;
      descriptionController.text = trail.description;
      cityController.text = trail.city;
      stateController.text = trail.state;
      distanceController.text = trail.distanceKm.toStringAsFixed(1);
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

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    cityController.dispose();
    stateController.dispose();
    distanceController.dispose();
    priceController.dispose();
    super.dispose();
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
        throw StateError('Permissão de localização negada.');
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
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: date ?? today,
      firstDate: DateTime(today.year - 1),
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

    setState(() => saving = true);

    final distance =
        double.tryParse(distanceController.text.replaceAll(',', '.')) ?? 0;

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
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
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
                  ? NetworkImageBox(url: existingImageUrl!, borderRadius: 18)
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
                            style: TextStyle(fontWeight: FontWeight.w900),
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
              DropdownMenuItem(value: 'Caminhada', child: Text('Caminhada')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => modality = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Distância do percurso (km)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              ],
            ),
          ),
          if (widget.isAgency) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: guides.any((guide) => guide.id == guideId)
                  ? guideId
                  : null,
              decoration: const InputDecoration(labelText: 'Guia responsável'),
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
