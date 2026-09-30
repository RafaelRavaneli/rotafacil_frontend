import 'package:flutter/material.dart';
import '../../utils/run_action.dart';

import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../management/trail_form_screen.dart';

class TrailsManagementScreen extends StatelessWidget {
  const TrailsManagementScreen({super.key, required this.isAgency});

  final bool isAgency;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trilhas',
                            style: TextStyle(
                              color: AppColors.green900,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gerencie suas trilhas e experiências',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        _openForm(context);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.terrain_rounded,
                        color: AppColors.green700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${store.managedTrails.length} trilha(s) cadastrada(s)',
                          style: const TextStyle(
                            color: AppColors.green900,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: store.managedTrails.isEmpty
                    ? _EmptyTrails(
                        onAdd: () {
                          _openForm(context);
                        },
                      )
                    : ListView.separated(
                        primary: false,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                        itemCount: store.managedTrails.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 10);
                        },
                        itemBuilder: (context, index) {
                          final trail = store.managedTrails[index];

                          return _TrailRow(
                            trail: trail,
                            onEdit: () {
                              _openForm(context, existing: trail);
                            },
                            onDelete: () {
                              _delete(context, trail);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {Trail? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return TrailFormScreen(isAgency: isAgency, existing: existing);
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, Trail trail) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir trilha?'),
          content: Text('Tem certeza que deseja excluir "${trail.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      final saved = await runAction(
        context,
        () => AppStore.instance.removeTrail(trail),
      );
      if (!saved) return;

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStore.instance.useBackend
                ? '${trail.name} foi desativada.'
                : '${trail.name} foi excluída.',
          ),
        ),
      );
    }
  }
}

class _TrailRow extends StatelessWidget {
  const _TrailRow({
    required this.trail,
    required this.onEdit,
    required this.onDelete,
  });

  final Trail trail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 82,
            child: NetworkImageBox(url: trail.imageUrl, borderRadius: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trail.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        trail.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _MiniChip(text: trail.difficulty),
                    _MiniChip(text: '${trail.distanceKm} km'),
                    _MiniChip(text: trail.status),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (value) {
              if (value == 'editar') {
                onEdit();
              }

              if (value == 'excluir') {
                onDelete();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'excluir',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 8),
                      Text('Excluir'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.green100,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.green700,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyTrails extends StatelessWidget {
  const _EmptyTrails({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.green100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.terrain_rounded,
                color: AppColors.green700,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhuma trilha cadastrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.green900,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crie sua primeira trilha para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar trilha'),
            ),
          ],
        ),
      ),
    );
  }
}
