import 'remote_guides_screen.dart';
import 'package:flutter/material.dart';
import '../../models/local_guide.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';

class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  Future<void> _invite(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final specialty = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Convidar guia'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: specialty,
                decoration: const InputDecoration(labelText: 'Especialidade'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty || email.text.trim().isEmpty) {
                return;
              }

              await AppStore.instance.addGuide(
                name: name.text.trim(),
                email: email.text.trim(),
                specialty: specialty.text.trim().isEmpty
                    ? 'Ecoturismo'
                    : specialty.text.trim(),
              );

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Convidar'),
          ),
        ],
      ),
    );

    name.dispose();
    email.dispose();
    specialty.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppStore.instance.useBackend) {
      return const RemoteGuidesScreen();
    }

    final store = AppStore.instance;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Guias da agência',
                            style: TextStyle(
                              color: AppColors.green900,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _invite(context),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Convidar'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                  sliver: SliverList.separated(
                    itemCount: store.agencyGuides.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _GuideRow(guide: store.agencyGuides[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.guide});
  final LocalGuide guide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.green100,
            child: Icon(Icons.person_rounded, color: AppColors.green700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  guide.email,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${guide.specialty} • ${guide.status}',
                  style: const TextStyle(
                    color: AppColors.green700,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'aprovar') {
                await AppStore.instance.updateGuideStatus(guide, 'Ativo');
              } else if (value == 'pendente') {
                await AppStore.instance.updateGuideStatus(guide, 'Pendente');
              } else if (value == 'remover') {
                await AppStore.instance.removeGuide(guide);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'aprovar', child: Text('Marcar como ativo')),
              PopupMenuItem(
                value: 'pendente',
                child: Text('Marcar como pendente'),
              ),
              PopupMenuItem(value: 'remover', child: Text('Remover guia')),
            ],
          ),
        ],
      ),
    );
  }
}
