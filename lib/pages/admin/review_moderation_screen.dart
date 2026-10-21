import '../../utils/controller_dialog.dart';
import 'package:flutter/material.dart';
import '../../state/app_store.dart';
import '../../utils/run_action.dart';
import '../../widgets/app_back_button.dart';

class ReviewModerationScreen extends StatefulWidget {
  const ReviewModerationScreen({super.key, this.load, this.apply});
  final Future<List<Map<String, dynamic>>> Function(String)? load;
  final Future<void> Function(String, String, String)? apply;
  @override
  State<ReviewModerationScreen> createState() => _ReviewModerationScreenState();
}

class _ReviewModerationScreenState extends State<ReviewModerationScreen> {
  String filter = 'denunciadas';
  late Future<List<Map<String, dynamic>>> future;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    future = fetch();
  }

  Future<List<Map<String, dynamic>>> fetch() =>
      widget.load?.call(filter) ?? AppStore.instance.moderationReviews(filter);
  void reload() {
    setState(() {
      future = fetch();
    });
  }

  Future<void> moderate(Map<String, dynamic> review, String action) async {
    final controller = TextEditingController();
    final reason = await showControllerDialog<String>(
      controllers: [controller],
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Justificar decisão'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo (3 a 500 caracteres)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 3) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Confirmar decisão'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    setState(() => busy = true);
    final saved = await runAction(
      context,
      () => (widget.apply ?? AppStore.instance.moderateReview)(
        review['id'].toString(),
        action,
        reason,
      ),
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (saved) reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Moderação de avaliações'),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: busy ? null : reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            initialValue: filter,
            items: const [
              DropdownMenuItem(
                value: 'denunciadas',
                child: Text('Denúncias pendentes'),
              ),
              DropdownMenuItem(value: 'todas', child: Text('Todas')),
              DropdownMenuItem(value: 'publicadas', child: Text('Publicadas')),
              DropdownMenuItem(value: 'ocultas', child: Text('Ocultas')),
            ],
            onChanged: busy
                ? null
                : (value) {
                    filter = value ?? filter;
                    reload();
                  },
            decoration: const InputDecoration(labelText: 'Situação'),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: reload,
                    child: const Text('Falha ao carregar. Tentar novamente'),
                  ),
                );
              }
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return const Center(
                  child: Text('Nenhuma avaliação neste filtro.'),
                );
              }
              return ListView(
                children: [
                  for (final review in reviews)
                    Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${review['nome_usuario'] ?? 'Participante'} · ${review['nota_roteiro'] ?? review['nota']}/5',
                            ),
                            Text('${review['status_moderacao']}'),
                            Text('${review['comentario'] ?? ''}'),
                            for (final report
                                in (review['denuncias'] as List? ?? []))
                              Text(
                                'Denúncia: ${report['motivo']} · ${report['descricao'] ?? ''} (${report['status']})',
                              ),
                            for (final event
                                in (review['historico'] as List? ?? []))
                              Text(
                                'Histórico: ${event['acao']} · ${event['motivo']} (${event['resultado']})',
                              ),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => moderate(
                                          review,
                                          review['status_moderacao'] == 'oculta'
                                              ? 'restaurar'
                                              : 'ocultar',
                                        ),
                                  child: Text(
                                    review['status_moderacao'] == 'oculta'
                                        ? 'Restaurar'
                                        : 'Ocultar',
                                  ),
                                ),
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => moderate(review, 'manter'),
                                  child: const Text(
                                    'Manter e concluir análise',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
