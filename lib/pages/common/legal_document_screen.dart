import 'package:flutter/material.dart';
import '../../services/legal_documents.dart';
import '../../services/api_client.dart';
import '../../config/app_config.dart';
import '../../services/session_service.dart';
import '../../utils/run_action.dart';
import '../../widgets/app_back_button.dart';

class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      for (final entry in {
        'termos': 'Termos de Uso',
        'privacidade': 'Política de Privacidade',
      }.entries)
        TextButton(
          style: light
              ? TextButton.styleFrom(foregroundColor: Colors.white)
              : null,
          onPressed: () => Navigator.pushNamed(context, '/${entry.key}'),
          child: Text(entry.value),
        ),
    ],
  );
}

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.documentKey});
  final String documentKey;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late final documents = LegalDocuments.load();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(fallbackLocation: '/'),
      title: Text(
        widget.documentKey == 'termos'
            ? 'Termos de Uso'
            : 'Política de Privacidade',
      ),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: documents,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Não foi possível carregar o documento. Tente novamente.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final document = snapshot.data![widget.documentKey] as Map;
        final version = DateTime.parse(document['version'] as String);
        return SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Versão ${version.day.toString().padLeft(2, '0')}/${version.month.toString().padLeft(2, '0')}/${version.year}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 20),
                      for (final section in document['sections'] as List) ...[
                        Text(
                          section[0] as String,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          section[1] as String,
                          style: const TextStyle(height: 1.6),
                        ),
                        const SizedBox(height: 24),
                      ],
                      const LegalLinks(),
                      const SizedBox(height: 16),
                      if (AppConfig.useBackend &&
                          SessionService.instance.token != null)
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Registrar aceite'),
                              content: const Text(
                                'Para contas existentes: confirme apenas após ler ambos os documentos. Isso registra o aceite dos Termos de Uso e a ciência da Política de Privacidade na sua conta. Não altera permissões opcionais.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    Navigator.pop(dialogContext);
                                    await runAction(context, () async {
                                      await ApiClient.instance.post(
                                        '/api/usuarios/aceite-legal',
                                        body: await LegalDocuments.acceptance(),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Aceite registrado.'),
                                          ),
                                        );
                                      }
                                    });
                                  },
                                  child: const Text('Li e aceito'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text('Registrar aceite na minha conta'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
