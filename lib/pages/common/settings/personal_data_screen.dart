import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/local_auth_service.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/document_validator.dart';
import '../../../widgets/profile_avatar.dart';

class PersonalDataScreen
    extends StatefulWidget {
  const PersonalDataScreen({
    super.key,
    required this.role,
  });

  final String role;

  @override
  State<PersonalDataScreen> createState() =>
      _PersonalDataScreenState();
}

class _PersonalDataScreenState
    extends State<PersonalDataScreen> {
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController phone;
  late final TextEditingController city;
  late final TextEditingController state;
  late final TextEditingController document;

  String? currentImageDataUrl;
  Uint8List? pickedImageBytes;
  bool removeCurrentImage = false;
  bool saving = false;

  bool get needsDocument {
    final normalized =
        widget.role.toLowerCase();

    return normalized == 'guia' ||
        normalized == 'agencia' ||
        normalized == 'agência';
  }

  String get documentLabel {
    return DocumentValidator.labelForRole(
      widget.role,
    );
  }

  @override
  void initState() {
    super.initState();

    final user =
        AppStore.instance.userForRole(
      widget.role,
    );

    name = TextEditingController(
      text: user.name,
    );

    email = TextEditingController(
      text: user.email,
    );

    phone = TextEditingController(
      text: user.phone,
    );

    city = TextEditingController(
      text: user.city,
    );

    state = TextEditingController(
      text: user.state,
    );

    document = TextEditingController(
      text: DocumentValidator
          .formatForRole(
        widget.role,
        user.document,
      ),
    );

    currentImageDataUrl =
        user.profileImageDataUrl;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    city.dispose();
    state.dispose();
    document.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file =
        await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 640,
    );

    if (file == null) return;

    final bytes =
        await file.readAsBytes();

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
    final newEmail =
        email.text.trim();

    if (name.text.trim().isEmpty ||
        newEmail.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Nome e e-mail são obrigatórios.',
          ),
        ),
      );

      return;
    }

    if (needsDocument &&
        !DocumentValidator.isValidForRole(
          widget.role,
          document.text,
        )) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '$documentLabel inválido.',
          ),
        ),
      );

      return;
    }

    setState(() => saving = true);

    final normalizedDocument =
        DocumentValidator.digitsOnly(
      document.text,
    );

    await AppStore.instance.updateUser(
      widget.role,
      name: name.text.trim(),
      email: newEmail,
      phone: phone.text.trim(),
      city: city.text.trim(),
      state:
          state.text.trim().toUpperCase(),
      document:
          needsDocument
              ? normalizedDocument
              : null,
      profileImageDataUrl:
          previewDataUrl,
      updateProfileImage: true,
    );

    await LocalAuthService.instance
        .updateEmail(
      role: widget.role,
      newEmail: newEmail,
    );

    if (needsDocument) {
      await LocalAuthService.instance
          .updateDocument(
        role: widget.role,
        document: normalizedDocument,
      );
    }

    if (!mounted) return;

    setState(() => saving = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Perfil atualizado com sucesso.',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar perfil',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ProfileAvatar(
                  dataUrl: previewDataUrl,
                  radius: 54,
                ),
                Positioned(
                  right: -4,
                  bottom: 0,
                  child: IconButton.filled(
                    onPressed: _pickPhoto,
                    icon: const Icon(
                      Icons
                          .photo_camera_outlined,
                    ),
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
                  icon: const Icon(
                    Icons
                        .photo_library_outlined,
                  ),
                  label: const Text(
                    'Escolher foto',
                  ),
                ),
                if (previewDataUrl != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        pickedImageBytes = null;
                        removeCurrentImage =
                            true;
                      });
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    label: const Text(
                      'Remover',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: name,
            decoration:
                const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType:
                TextInputType.emailAddress,
            decoration:
                const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(
                Icons.email_outlined,
              ),
            ),
          ),
          if (needsDocument) ...[
            const SizedBox(height: 12),
            TextField(
              controller: document,
              keyboardType:
                  TextInputType.number,
              decoration:
                  InputDecoration(
                labelText: documentLabel,
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                ),
                helperText:
                    '$documentLabel é obrigatório para este perfil.',
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType:
                TextInputType.phone,
            decoration:
                const InputDecoration(
              labelText: 'Telefone',
              prefixIcon: Icon(
                Icons.phone_outlined,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: city,
                  decoration:
                      const InputDecoration(
                    labelText: 'Cidade',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: state,
                  maxLength: 2,
                  textCapitalization:
                      TextCapitalization
                          .characters,
                  decoration:
                      const InputDecoration(
                    labelText: 'UF',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                saving ? null : _save,
            icon: const Icon(
              Icons.save_outlined,
            ),
            label: Text(
              saving
                  ? 'Salvando...'
                  : 'Salvar alterações',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'A foto, dados pessoais e documento ficam '
            'salvos neste dispositivo no modo local.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
