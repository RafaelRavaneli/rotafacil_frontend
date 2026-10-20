import '../../../widgets/brazil_location_fields.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/local_auth_service.dart';
import '../../../utils/run_action.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/document_validator.dart';
import '../../../widgets/profile_avatar.dart';
import '../../../widgets/cadastur_fields.dart';
import '../../../utils/cadastur_validator.dart';
import '../../../utils/date_time_format.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key, required this.role});

  final String role;

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController phone;
  late final TextEditingController city;
  late final TextEditingController state;
  late final TextEditingController document;
  late final TextEditingController cadastur;
  late final TextEditingController cadasturValidity;
  late final TextEditingController emergencyName;
  late final TextEditingController emergencyPhone;
  late final TextEditingController professionalDescription;
  late final TextEditingController specialties;

  String? currentImageDataUrl;
  Uint8List? pickedImageBytes;
  bool removeCurrentImage = false;
  bool saving = false;
  bool allowPop = false;
  late final Map<String, String> initialValues;

  bool get needsDocument {
    final normalized = widget.role.toLowerCase();

    return normalized == 'guia' ||
        normalized == 'agencia' ||
        normalized == 'agência';
  }

  String get documentLabel {
    return DocumentValidator.labelForRole(widget.role);
  }

  @override
  void initState() {
    super.initState();

    final user = AppStore.instance.userForRole(widget.role);

    name = TextEditingController(text: user.name);

    email = TextEditingController(text: user.email);

    phone = TextEditingController(text: user.phone);

    city = TextEditingController(text: user.city);

    state = TextEditingController(text: user.state);

    document = TextEditingController(
      text: DocumentValidator.formatForRole(widget.role, user.document),
    );
    emergencyName = TextEditingController(text: user.emergencyContactName);
    cadastur = TextEditingController(text: user.cadasturNumber);
    cadasturValidity = TextEditingController(
      text: formatBrazilianDate(user.cadasturValidUntil),
    );
    emergencyPhone = TextEditingController(text: user.emergencyContactPhone);
    professionalDescription = TextEditingController(
      text: user.professionalDescription,
    );
    specialties = TextEditingController(text: user.specialties.join(', '));

    currentImageDataUrl = user.profileImageDataUrl;
    initialValues = _currentValues();
  }

  Map<String, String> _currentValues() => {
    'name': name.text,
    'email': email.text,
    'phone': phone.text,
    'city': city.text,
    'state': state.text,
    'document': document.text,
    'cadastur': cadastur.text,
    'cadasturValidity': cadasturValidity.text,
    'emergencyName': emergencyName.text,
    'emergencyPhone': emergencyPhone.text,
    'professionalDescription': professionalDescription.text,
    'specialties': specialties.text,
  };

  bool get hasUnsavedChanges {
    if (pickedImageBytes != null || removeCurrentImage) return true;
    final current = _currentValues();
    return initialValues.entries.any(
      (entry) => current[entry.key] != entry.value,
    );
  }

  void _popWithoutGuard() {
    if (!mounted) return;
    setState(() => allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _handleBack() async {
    if (saving) return;
    if (!hasUnsavedChanges) {
      _popWithoutGuard();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('Existem alterações que ainda não foram salvas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    _popWithoutGuard();
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    city.dispose();
    state.dispose();
    document.dispose();
    cadastur.dispose();
    cadasturValidity.dispose();
    emergencyName.dispose();
    emergencyPhone.dispose();
    professionalDescription.dispose();
    specialties.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 640,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();

    if (!mounted) return;

    setState(() {
      pickedImageBytes = bytes;
      removeCurrentImage = false;
    });
  }

  String? get previewDataUrl {
    if (pickedImageBytes != null) {
      return 'data:image/jpeg;base64,'
          '${base64Encode(pickedImageBytes!)}';
    }

    if (removeCurrentImage) {
      return null;
    }

    return currentImageDataUrl;
  }

  Future<void> _save() async {
    final newEmail = email.text.trim();

    if (name.text.trim().isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e e-mail são obrigatórios.')),
      );

      return;
    }

    if (needsDocument &&
        !DocumentValidator.isValidForRole(widget.role, document.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$documentLabel inválido.')));

      return;
    }

    final hasCadastur =
        needsDocument &&
        (cadastur.text.trim().isNotEmpty ||
            cadasturValidity.text.isNotEmpty ||
            initialValues['cadastur']!.isNotEmpty);
    final cadasturError = hasCadastur
        ? CadasturValidator.error(cadastur.text)
        : null;
    if (cadasturError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cadasturError)));
      return;
    }
    setState(() => saving = true);

    final normalizedDocument = DocumentValidator.digitsOnly(document.text);

    final saved = await runAction(context, () async {
      await AppStore.instance.updateUser(
        widget.role,
        name: name.text.trim(),
        email: newEmail,
        phone: phone.text.trim(),
        city: city.text.trim(),
        state: state.text.trim().toUpperCase(),
        document: needsDocument ? normalizedDocument : null,
        cadasturNumber: hasCadastur
            ? CadasturValidator.normalize(cadastur.text)
            : null,
        cadasturValidUntil: hasCadastur
            ? (parseAppDateTime(
                    cadasturValidity.text,
                  )?.toIso8601String().split('T').first ??
                  '')
            : null,
        profileImageDataUrl: previewDataUrl,
        updateProfileImage: true,
        emergencyContactName: emergencyName.text.trim(),
        emergencyContactPhone: emergencyPhone.text.trim(),
        professionalDescription: needsDocument
            ? professionalDescription.text.trim()
            : null,
        specialties: needsDocument
            ? specialties.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .toList()
            : null,
      );

      if (!AppStore.instance.useBackend) {
        await LocalAuthService.instance.updateEmail(
          role: widget.role,
          newEmail: newEmail,
        );

        if (needsDocument) {
          await LocalAuthService.instance.updateDocument(
            role: widget.role,
            document: normalizedDocument,
          );
        }
      }
    });
    if (!mounted) return;

    setState(() => saving = false);
    if (!saved) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso.')),
    );

    _popWithoutGuard();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Editar perfil',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(dataUrl: previewDataUrl, radius: 54),
                  Positioned(
                    right: -4,
                    bottom: 0,
                    child: IconButton.filled(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Escolher foto'),
                  ),
                  if (previewDataUrl != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          pickedImageBytes = null;
                          removeCurrentImage = true;
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remover'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            if (needsDocument) ...[
              const SizedBox(height: 12),
              TextField(
                controller: document,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: documentLabel,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  helperText: '$documentLabel é obrigatório para este perfil.',
                ),
              ),
              const SizedBox(height: 16),
              CadasturFields(
                number: cadastur,
                validUntil: cadasturValidity,
                enabled: !saving,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            BrazilLocationFields(enabled: !saving, city: city, state: state),
            if (needsDocument) ...[
              const SizedBox(height: 18),
              const Text(
                'Perfil profissional público',
                style: TextStyle(
                  color: AppColors.forest,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Esses dados ajudam o turista a conhecer o responsável. Documento, e-mail e telefone não são publicados.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: professionalDescription,
                maxLines: 4,
                maxLength: 600,
                decoration: const InputDecoration(
                  labelText: 'Apresentação profissional',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specialties,
                decoration: const InputDecoration(
                  labelText: 'Especialidades',
                  helperText: 'Separe por vírgulas. Ex.: trekking, cachoeiras',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'Contato de emergência',
              style: TextStyle(
                color: AppColors.forest,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Disponível somente para responsáveis autorizados durante uma reserva ativa.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emergencyName,
              decoration: const InputDecoration(
                labelText: 'Nome do contato',
                prefixIcon: Icon(Icons.emergency_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emergencyPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone de emergência',
                prefixIcon: Icon(Icons.phone_in_talk_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(saving ? 'Salvando...' : 'Salvar alterações'),
            ),
            const SizedBox(height: 10),
            const Text(
              'A foto, dados pessoais e documento ficam '
              'salvos neste dispositivo no modo local.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
