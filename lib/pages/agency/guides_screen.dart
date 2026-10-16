import 'package:flutter/material.dart';
import '../../models/local_guide.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/run_action.dart';
import '../../widgets/guide_catalog_card.dart';
import 'remote_guides_screen.dart';

class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    if (store.useBackend) return const RemoteGuidesScreen();
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Organize sua equipe',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Consulte os guias e suas situações.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),
                  const GuideCollectionNotice(
                    title: 'Demonstração local',
                    message:
                        'Os registros desta tela ficam neste dispositivo. Convites reais e respostas de guias estão disponíveis no modo conectado ao backend.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const _LocalGuideDialog(),
                    ),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Adicionar guia'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${store.agencyGuides.length} guia(s)',
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (store.agencyGuides.isEmpty)
                    const GuideCollectionNotice(
                      title: 'Nenhum guia registrado',
                      message:
                          'Adicione um guia para experimentar a organização da equipe.',
                    ),
                  ...store.agencyGuides.map(
                    (guide) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LocalGuideCard(guide: guide),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalGuideCard extends StatelessWidget {
  const _LocalGuideCard({required this.guide});
  final LocalGuide guide;

  Future<void> _remove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover guia local?'),
        content: Text(guide.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await runAction(context, () => AppStore.instance.removeGuide(guide));
    }
  }

  @override
  Widget build(BuildContext context) => GuideCatalogCard(
    name: guide.name,
    subtitle: [
      guide.email,
      guide.specialty,
    ].where((value) => value.isNotEmpty).join('\n'),
    status: guide.status,
    actions: [
      Align(
        alignment: Alignment.centerRight,
        child: PopupMenuButton<String>(
          tooltip: 'Gerenciar guia local',
          onSelected: (value) async {
            if (value == 'remover') {
              await _remove(context);
              return;
            }
            await runAction(
              context,
              () => AppStore.instance.updateGuideStatus(guide, value),
            );
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'Ativo', child: Text('Marcar como ativo')),
            PopupMenuItem(
              value: 'Pendente',
              child: Text('Marcar como pendente'),
            ),
            PopupMenuItem(value: 'remover', child: Text('Remover guia')),
          ],
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Gerenciar registro',
              style: TextStyle(
                color: AppColors.forest,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _LocalGuideDialog extends StatefulWidget {
  const _LocalGuideDialog();
  @override
  State<_LocalGuideDialog> createState() => _LocalGuideDialogState();
}

class _LocalGuideDialogState extends State<_LocalGuideDialog> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final specialty = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    specialty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    final saved = await runAction(
      context,
      () => AppStore.instance.addGuide(
        name: name.text.trim(),
        email: email.text.trim(),
        specialty: specialty.text.trim().isEmpty
            ? 'Ecoturismo'
            : specialty.text.trim(),
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Adicionar guia local'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Registro demonstrativo; não envia convite para outra pessoa.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: name,
                enabled: !saving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: email,
                enabled: !saving,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (value) =>
                    value == null ||
                        !RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(value.trim())
                    ? 'Informe um e-mail válido.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: specialty,
                enabled: !saving,
                decoration: const InputDecoration(
                  labelText: 'Especialidade (opcional)',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Voltar'),
      ),
      FilledButton(
        onPressed: saving ? null : _save,
        child: Text(saving ? 'Salvando...' : 'Salvar guia'),
      ),
    ],
  );
}
