import '../../widgets/app_back_button.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/professional_document.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/run_action.dart';
import '../../widgets/status_pill.dart';

class ProfessionalDocumentsScreen extends StatefulWidget {
  const ProfessionalDocumentsScreen({super.key});

  @override
  State<ProfessionalDocumentsScreen> createState() =>
      _ProfessionalDocumentsScreenState();
}

class _ProfessionalDocumentsScreenState
    extends State<ProfessionalDocumentsScreen> {
  late Future<List<ProfessionalDocument>> future;
  bool uploading = false;

  static const types = <String, String>{
    'cadastur': 'Cadastur',
    'certificacao': 'Certificação',
    'identificacao_profissional': 'Identificação profissional',
    'outro': 'Outro documento',
  };

  @override
  void initState() {
    super.initState();
    future = AppStore.instance.professionalDocuments();
  }

  void _reload() {
    setState(() => future = AppStore.instance.professionalDocuments());
  }

  Future<void> _upload() async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Tipo do documento'),
        children: types.entries
            .map(
              (entry) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, entry.key),
                child: Text(entry.value),
              ),
            )
            .toList(),
      ),
    );
    if (type == null || !mounted) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2200,
      maxHeight: 2200,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A imagem deve ter no máximo 5 MB.')),
        );
      }
      return;
    }
    setState(() => uploading = true);
    final uploaded = await runAction(
      context,
      () => AppStore.instance.uploadProfessionalDocument(
        bytes: bytes,
        fileName: file.name,
        documentType: type,
      ),
    );
    if (!mounted) return;
    setState(() => uploading = false);
    if (uploaded) _reload();
  }

  Future<void> _preview(ProfessionalDocument document) async {
    final bytes = await runValueAction<Uint8List>(
      context,
      () => AppStore.instance.professionalDocumentBytes(document.id),
    );
    if (bytes == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
          child: InteractiveViewer(child: Image.memory(bytes)),
        ),
      ),
    );
  }

  Future<void> _delete(ProfessionalDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir documento?'),
        content: const Text(
          'O documento será removido do armazenamento privado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await runAction(
      context,
      () => AppStore.instance.deleteProfessionalDocument(document.id),
    );
    if (deleted && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/perfil'),
        title: const Text(
          'Documentos profissionais',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: uploading ? null : _upload,
        icon: uploading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file_outlined),
        label: Text(uploading ? 'Enviando...' : 'Enviar documento'),
      ),
      body: FutureBuilder<List<ProfessionalDocument>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Não foi possível carregar seus documentos.',
              action: _reload,
            );
          }
          final documents = snapshot.data ?? const [];
          if (documents.isEmpty) {
            return _StateMessage(
              icon: Icons.badge_outlined,
              message:
                  'Envie uma imagem do documento profissional para análise.',
              action: _reload,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: documents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final document = documents[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                types[document.documentType] ??
                                    document.documentType,
                                style: const TextStyle(
                                  color: AppColors.green900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            StatusPill(label: document.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(document.fileName),
                        Text(
                          '${(document.size / 1024).ceil()} KB',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        if (document.reviewNote.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Análise: ${document.reviewNote}',
                            style: const TextStyle(color: AppColors.red),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _preview(document),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Visualizar'),
                            ),
                            if (document.status != 'aprovado')
                              TextButton.icon(
                                onPressed: () => _delete(document),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Excluir'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String message;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.green700),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: action, child: const Text('Atualizar')),
          ],
        ),
      ),
    );
  }
}
