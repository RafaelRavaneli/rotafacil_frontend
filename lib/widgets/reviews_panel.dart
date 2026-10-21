import '../utils/controller_dialog.dart';
import 'package:flutter/material.dart';
import '../models/trail_experience.dart';
import '../state/app_store.dart';
import '../utils/run_action.dart';
import '../utils/date_time_format.dart';

class ReviewsPanel extends StatefulWidget {
  const ReviewsPanel({
    super.key,
    required this.id,
    this.professional = false,
    this.role = '',
    this.load,
  });
  final String id;
  final bool professional;
  final String role;
  final Future<List<TrailReview>> Function()? load;
  @override
  State<ReviewsPanel> createState() => _ReviewsPanelState();
}

class _ReviewsPanelState extends State<ReviewsPanel>
    with WidgetsBindingObserver {
  late Future<List<TrailReview>> future;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppStore.instance.addListener(reload);
    future = fetch();
  }

  Future<List<TrailReview>> fetch() =>
      widget.load?.call() ??
      (widget.professional
          ? AppStore.instance.professionalReviews(widget.id)
          : AppStore.instance.reviewsFor(widget.id));
  void reload() {
    setState(() {
      future = fetch();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reload();
  }

  @override
  void didUpdateWidget(covariant ReviewsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.professional != widget.professional) {
      future = fetch();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppStore.instance.removeListener(reload);
    super.dispose();
  }

  Future<void> report(TrailReview review) async {
    var reason = 'conteudo_ofensivo';
    final description = TextEditingController();
    final choice = await showControllerDialog<(String, String)>(
      controllers: [description],
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Denunciar avaliação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'conteudo_ofensivo',
                      child: Text('Conteúdo ofensivo'),
                    ),
                    DropdownMenuItem(
                      value: 'dados_pessoais',
                      child: Text('Exposição de dados pessoais'),
                    ),
                    DropdownMenuItem(value: 'spam', child: Text('Spam')),
                    DropdownMenuItem(value: 'outro', child: Text('Outro')),
                  ],
                  onChanged: (value) => update(() => reason = value ?? reason),
                ),
                TextField(
                  controller: description,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                  ),
                ),
                const Text(
                  'A denúncia será analisada pela administração. Não inclua dados pessoais desnecessários.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, (reason, description.text.trim())),
              child: const Text('Enviar denúncia'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final saved = await runAction(
      context,
      () => AppStore.instance.reportReview(review.id, choice.$1, choice.$2),
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denúncia registrada para análise.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Avaliações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Atualizar avaliações',
            onPressed: reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      FutureBuilder<List<TrailReview>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            return TextButton(
              onPressed: reload,
              child: const Text(
                'Não foi possível carregar as avaliações. Tentar novamente',
              ),
            );
          }
          final reviews = snapshot.data ?? const [];
          if (reviews.isEmpty) {
            return const Text('Ainda não há avaliações publicadas.');
          }
          return Column(
            children: [
              for (final review in reviews)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${review.userName} · ${widget.role == 'agencia'
                              ? review.agencyRating ?? review.rating
                              : widget.role == 'guia'
                              ? review.guideRating ?? review.rating
                              : review.rating}/5',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (review.createdAt.isNotEmpty)
                          Text(
                            formatBrazilianDateTime(
                              parseAppDateTime(review.createdAt),
                            ),
                          ),
                        Text(
                          review.comment.isEmpty
                              ? 'Sem comentário.'
                              : review.comment,
                        ),
                        if (review.id.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => report(review),
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Denunciar'),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
