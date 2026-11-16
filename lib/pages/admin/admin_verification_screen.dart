import '../../utils/controller_dialog.dart';
import '../../utils/date_time_format.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/professional_document.dart';
import '../../services/notification_service.dart';
import '../../services/session_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/run_action.dart';
import '../../widgets/status_pill.dart';
import '../auth/welcome_screen.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  late Future<List<ProfessionalDocument>> future;
  String filter = 'pendente';

  @override
  void initState() {
    super.initState();
    future = AppStore.instance.professionalDocuments(status: filter);
  }

  void _reload() {
    setState(
      () => future = AppStore.instance.professionalDocuments(
        status: filter == 'todos' ? null : filter,
      ),
    );
  }

  Future<void> _logout() async {
    await NotificationService.instance.unregisterOnLogout();
    await SessionService.instance.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
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
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
          child: InteractiveViewer(child: Image.memory(bytes)),
        ),
      ),
    );
  }

  Future<void> _review(ProfessionalDocument document, String status) async {
    var note = '';
    if (status == 'rejeitado') {
      final controller = TextEditingController();
      final result = await showControllerDialog<String>(
        controllers: [controller],
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Motivo da rejeição'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Explique o que precisa ser corrigido.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Rejeitar'),
            ),
          ],
        ),
      );
      if (result == null || result.isEmpty || !mounted) return;
      note = result;
    }

    final reviewed = await runAction(
      context,
      () => AppStore.instance.reviewProfessionalDocument(
        id: document.id,
        status: status,
        note: note,
      ),
    );
    if (reviewed && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verificação profissional',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: DropdownButtonFormField<String>(
              initialValue: filter,
              items: const [
                DropdownMenuItem(value: 'pendente', child: Text('Pendentes')),
                DropdownMenuItem(value: 'aprovado', child: Text('Aprovados')),
                DropdownMenuItem(value: 'rejeitado', child: Text('Rejeitados')),
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
              ],
              onChanged: (value) {
                if (value == null) return;
                filter = value;
                _reload();
              },
              decoration: const InputDecoration(labelText: 'Situação'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProfessionalDocument>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  );
                }
                final documents = snapshot.data ?? const [];
                if (documents.isEmpty) {
                  return const Center(
                    child: Text('Nenhum documento nesta situação.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
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
                                      document.userName.isEmpty
                                          ? document.userId
                                          : document.userName,
                                      style: const TextStyle(
                                        color: AppColors.green900,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  StatusPill(label: document.status),
                                ],
                              ),
                              if (document.userEmail.isNotEmpty)
                                Text(document.userEmail),
                              const SizedBox(height: 6),
                              Text(
                                '${document.documentType} • ${document.fileName}',
                              ),
                              Text(
                                document.cadasturNumber.isEmpty
                                    ? 'Cadastur não informado'
                                    : 'Cadastur: ${document.cadasturNumber}',
                              ),
                              if (document.cadasturValidUntil.isNotEmpty)
                                Text(
                                  'Validade do Cadastur: ${formatBrazilianDate(document.cadasturValidUntil)}',
                                ),
                              if (document.reviewNote.isNotEmpty)
                                Text('Observação: ${document.reviewNote}'),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _preview(document),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('Visualizar'),
                                  ),
                                  if (document.status == 'pendente') ...[
                                    FilledButton.icon(
                                      onPressed: () =>
                                          _review(document, 'aprovado'),
                                      icon: const Icon(Icons.check_rounded),
                                      label: const Text('Aprovar'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _review(document, 'rejeitado'),
                                      icon: const Icon(Icons.close_rounded),
                                      label: const Text('Rejeitar'),
                                    ),
                                  ],
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
          ),
        ],
      ),
    );
  }
}
