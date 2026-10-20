import 'package:flutter/material.dart';

import '../../models/availability.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/run_action.dart';
import '../../utils/date_time_format.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  bool loading = true;
  String? error;
  List<Availability> items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      items = await AppStore.instance.availabilities();
    } catch (failure) {
      error = failure.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _add() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AvailabilityForm(),
    );
    if (created == true) await _load();
  }

  Future<void> _remove(Availability item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover registro?'),
        content: Text(
          '${_dateLabel(item.date)} • ${item.startTime}–${item.endTime}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final removed = await runAction(
      context,
      () => AppStore.instance.deleteAvailability(item.id),
    );
    if (removed) await _load();
  }

  String _dateLabel(String value) {
    return formatBrazilianDate(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário e disponibilidade')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            const Text(
              'Organize horários disponíveis e bloqueios',
              style: TextStyle(
                color: AppColors.forest,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Atividades não podem ser atribuídas durante um bloqueio ou conflito de horário.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (!loading && error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Text('Não foi possível carregar o calendário.'),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            if (!loading && error == null && items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhuma disponibilidade cadastrada.'),
                ),
              ),
            ...items.map(
              (item) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.blocked
                        ? AppColors.amber100
                        : AppColors.green100,
                    child: Icon(
                      item.blocked
                          ? Icons.block_outlined
                          : Icons.event_available_outlined,
                      color: item.blocked
                          ? AppColors.amber700
                          : AppColors.green700,
                    ),
                  ),
                  title: Text(
                    '${_dateLabel(item.date)} • ${item.startTime}–${item.endTime}',
                  ),
                  subtitle: Text(
                    [
                      item.blocked ? 'Bloqueado' : 'Disponível',
                      if (item.capacity != null) '${item.capacity} vagas',
                      if (item.note.isNotEmpty) item.note,
                    ].join(' • '),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remover',
                    onPressed: () => _remove(item),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityForm extends StatefulWidget {
  const _AvailabilityForm();

  @override
  State<_AvailabilityForm> createState() => _AvailabilityFormState();
}

class _AvailabilityFormState extends State<_AvailabilityForm> {
  final note = TextEditingController();
  final capacity = TextEditingController();
  DateTime? date;
  TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 12, minute: 0);
  String type = 'disponivel';
  bool saving = false;

  @override
  void dispose() {
    note.dispose();
    capacity.dispose();
    super.dispose();
  }

  String _apiDate() => date == null
      ? ''
      : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-'
            '${date!.day.toString().padLeft(2, '0')}';

  String _apiTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: date ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2035),
    );
    if (selected != null) setState(() => date = selected);
  }

  Future<void> _pickTime(bool isStart) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? start : end,
    );
    if (selected == null) return;
    setState(() => isStart ? start = selected : end = selected);
  }

  Future<void> _save() async {
    if (date == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione a data.')));
      return;
    }
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O horário final deve ser posterior ao inicial.'),
        ),
      );
      return;
    }
    final vacancies = capacity.text.trim().isEmpty
        ? null
        : int.tryParse(capacity.text.trim());
    if (type == 'disponivel' && vacancies != null && vacancies <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma quantidade válida de vagas.'),
        ),
      );
      return;
    }
    setState(() => saving = true);
    final saved = await runAction(
      context,
      () => AppStore.instance.createAvailability(
        date: _apiDate(),
        startTime: _apiTime(start),
        endTime: _apiTime(end),
        type: type,
        note: note.text.trim(),
        capacity: type == 'disponivel' ? vacancies : null,
      ),
    );
    if (mounted) setState(() => saving = false);
    if (saved && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Novo registro',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'disponivel',
                  label: Text('Disponível'),
                  icon: Icon(Icons.event_available_outlined),
                ),
                ButtonSegment(
                  value: 'bloqueio',
                  label: Text('Bloqueio'),
                  icon: Icon(Icons.block_outlined),
                ),
              ],
              selected: {type},
              onSelectionChanged: (values) =>
                  setState(() => type = values.first),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                date == null
                    ? 'Selecionar data'
                    : '${date!.day.toString().padLeft(2, '0')}/'
                          '${date!.month.toString().padLeft(2, '0')}/${date!.year}',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(true),
                    child: Text('Início: ${start.format(context)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(false),
                    child: Text('Fim: ${end.format(context)}'),
                  ),
                ),
              ],
            ),
            if (type == 'disponivel') ...[
              const SizedBox(height: 12),
              TextField(
                controller: capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Vagas padrão (opcional)',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Observação'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: saving ? null : _save,
              child: Text(saving ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
