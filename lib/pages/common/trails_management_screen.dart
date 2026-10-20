import 'package:flutter/material.dart';

import '../../utils/run_action.dart';

import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../navigation/app_routes.dart';
import '../management/trail_form_screen.dart';

class TrailsManagementScreen extends StatefulWidget {
  const TrailsManagementScreen({super.key, required this.isAgency});

  final bool isAgency;

  @override
  State<TrailsManagementScreen> createState() =>
      _TrailsManagementScreenState();
}

class _TrailsManagementScreenState extends State<TrailsManagementScreen> {
  String _filter = 'Não arquivados';
  DateTimeRange? _period;

  List<Trail> _filteredTrails(List<Trail> trails) {
    final statusFiltered = switch (_filter) {
      'Ativos' => trails
          .where((trail) => TrailStatus.isActive(trail.status) && !trail.archived)
          .toList(),
      'Desativados' => trails
          .where((trail) => TrailStatus.isInactive(trail.status) && !trail.archived)
          .toList(),
      'Arquivados' => trails.where((trail) => trail.archived).toList(),
      'Todos' => trails,
      _ => trails.where((trail) => !trail.archived).toList(),
    };
    final period = _period;
    if (period == null) return statusFiltered;
    final periodEnd = DateTime(
      period.end.year,
      period.end.month,
      period.end.day,
      23,
      59,
      59,
    );
    return statusFiltered.where((trail) {
      final start = trail.startsAt;
      if (start == null) return false;
      final end = trail.endsAt ?? start;
      return !end.isBefore(period.start) && !start.isAfter(periodEnd);
    }).toList();
  }

  Future<void> _selectPeriod(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: _period,
      helpText: 'Período dos roteiros',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
    );
    if (selected != null && mounted) setState(() => _period = selected);
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final managedTrails = store.managedTrails;
          final visibleTrails = _filteredTrails(managedTrails);
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Meus roteiros',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gerencie seus roteiros e experiências',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _openForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Novo roteiro'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _filter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Exibir roteiros',
                            prefixIcon: Icon(Icons.filter_list_rounded),
                          ),
                          items: const [
                            'Não arquivados',
                            'Ativos',
                            'Desativados',
                            'Arquivados',
                            'Todos',
                          ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _filter = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectPeriod(context),
                                icon: const Icon(Icons.date_range_outlined),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _period == null
                                        ? 'Filtrar por período'
                                        : '${_dateLabel(_period!.start)} a ${_dateLabel(_period!.end)}',
                                  ),
                                ),
                              ),
                            ),
                            if (_period != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Limpar período',
                                onPressed: () => setState(() => _period = null),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ],
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
                              '${visibleTrails.length} de ${managedTrails.length} roteiro(s)',
                              style: const TextStyle(
                                color: AppColors.green900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: visibleTrails.isEmpty
                        ? _EmptyTrails(
                            onAdd: () {
                              _openForm(context);
                            },
                          )
                        : ListView.separated(
                            primary: false,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                            itemCount: visibleTrails.length,
                            separatorBuilder: (context, index) {
                              return const SizedBox(height: 10);
                            },
                            itemBuilder: (context, index) {
                              final trail = visibleTrails[index];

                              return _TrailRow(
                                trail: trail,
                                onEdit: () {
                                  _openForm(context, existing: trail);
                                },
                                onDelete: () {
                                  TrailStatus.isInactive(trail.status)
                                      ? _activate(context, trail)
                                      : _delete(context, trail);
                                },
                                onArchive: () => _archive(context, trail),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {Trail? existing}) {
    AppRoutes.push(
      context,
      existing == null ? AppRoutes.newTrail : AppRoutes.editTrail(existing.id),
      (_) => TrailFormScreen(isAgency: widget.isAgency, existing: existing),
    );
  }

  Future<void> _delete(BuildContext context, Trail trail) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            AppStore.instance.useBackend
                ? 'Desativar roteiro?'
                : 'Excluir roteiro?',
          ),
          content: Text(
            AppStore.instance.useBackend
                ? 'O roteiro "${trail.name}" deixará de aparecer na busca. Reservas ativas impedem a desativação; o histórico será preservado.'
                : 'Excluir "${trail.name}"? Reservas ativas impedem a exclusão; o histórico será preservado.',
          ),
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
              child: Text(
                AppStore.instance.useBackend ? 'Desativar' : 'Excluir',
              ),
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

  Future<void> _activate(BuildContext context, Trail trail) async {
    final saved = await runAction(
      context,
      () => AppStore.instance.activateTrail(trail),
    );
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${trail.name} foi reativado.')));
  }

  Future<void> _archive(BuildContext context, Trail trail) async {
    final archive = !trail.archived;
    final saved = await runAction(
      context,
      () => AppStore.instance.archiveTrail(trail, archived: archive),
    );
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          archive
              ? '${trail.name} foi arquivado.'
              : '${trail.name} voltou para roteiros desativados.',
        ),
      ),
    );
  }
}

class _TrailRow extends StatelessWidget {
  const _TrailRow({
    required this.trail,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
  });

  final Trail trail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 132,
            child: NetworkImageBox(url: trail.imageUrl, borderRadius: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trail.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
                        maxLines: 2,
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
                Text(
                  'R\$ ${trail.price.toStringAsFixed(2).replaceAll('.', ',')} por pessoa',
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trail.date.isNotEmpty)
                  Text(
                    trail.date,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _MiniChip(text: trail.difficulty),
                    _MiniChip(text: trail.distanceLabel),
                    _MiniChip(text: trail.status),
                    if (trail.archived) const _MiniChip(text: 'Arquivado'),
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

              if (value == 'status') {
                onDelete();
              }

              if (value == 'archive') {
                onArchive();
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
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
                  value: 'status',
                  child: Row(
                    children: [
                      Icon(
                        AppStore.instance.useBackend &&
                                TrailStatus.isInactive(trail.status)
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStore.instance.useBackend
                            ? (TrailStatus.isInactive(trail.status)
                                  ? 'Reativar'
                                  : 'Desativar')
                            : 'Excluir',
                      ),
                    ],
                  ),
                ),
                if (AppStore.instance.useBackend &&
                    (trail.archived || TrailStatus.isInactive(trail.status)))
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(
                          trail.archived
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                        ),
                        const SizedBox(width: 8),
                        Text(trail.archived ? 'Desarquivar' : 'Arquivar'),
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
          fontWeight: FontWeight.w600,
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
              'Nenhum roteiro cadastrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.green900,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crie seu primeiro roteiro para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar roteiro'),
            ),
          ],
        ),
      ),
    );
  }
}
