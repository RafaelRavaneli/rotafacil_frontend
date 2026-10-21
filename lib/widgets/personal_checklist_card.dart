import 'package:flutter/material.dart';
import '../models/trail.dart';
import '../models/local_booking.dart';
import '../models/packing_checklist.dart';
import '../state/app_store.dart';

class PersonalChecklistCard extends StatefulWidget {
  const PersonalChecklistCard({
    super.key,
    required this.booking,
    required this.trail,
    this.load,
    this.save,
  });
  final LocalBooking booking;
  final Trail trail;
  final Future<PackingChecklist> Function()? load;
  final Future<PackingChecklist> Function(String id, bool checked)? save;
  @override
  State<PersonalChecklistCard> createState() => _PersonalChecklistCardState();
}

class _PersonalChecklistCardState extends State<PersonalChecklistCard>
    with WidgetsBindingObserver {
  PackingChecklist? checklist;
  bool loading = true;
  bool saving = false;
  String? error;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !saving) _load();
  }

  @override
  void didUpdateWidget(PersonalChecklistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id ||
        oldWidget.booking.status != widget.booking.status ||
        oldWidget.trail.requiredItems.join('\n') !=
            widget.trail.requiredItems.join('\n') ||
        oldWidget.trail.recommendedItems.join('\n') !=
            widget.trail.recommendedItems.join('\n')) {
      _load();
    }
  }

  Future<void> _load() async {
    final current = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result =
          await (widget.load?.call() ??
              AppStore.instance.packingChecklistFor(
                widget.booking,
                widget.trail,
              ));
      if (mounted && generation == current) setState(() => checklist = result);
    } catch (_) {
      if (mounted && generation == current) {
        setState(
          () => error =
              'Não foi possível carregar seu checklist. Tente novamente.',
        );
      }
    } finally {
      if (mounted && generation == current) setState(() => loading = false);
    }
  }

  Future<void> _save(String id, bool checked) async {
    if (saving || loading) return;
    final current = generation;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final result =
          await (widget.save?.call(id, checked) ??
              AppStore.instance.updatePackingItem(
                widget.booking,
                widget.trail,
                id,
                checked,
              ));
      if (mounted && generation == current) setState(() => checklist = result);
    } catch (_) {
      if (mounted && generation == current) {
        setState(
          () => error =
              'Não foi possível salvar a marcação. Confira a conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayed = checklist ?? PackingChecklist.fromTrail(widget.trail);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Meu checklist',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar checklist',
                  onPressed: loading || saving ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const Text(
              'Sua preparação é particular e vale apenas para esta reserva.',
            ),
            if (loading || saving) const LinearProgressIndicator(),
            if (!loading && checklist != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${displayed.prepared} de ${displayed.items.length} itens preparados • ${displayed.requiredRemaining} obrigatórios pendentes',
                ),
              ),
            if (error != null) ...[
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: loading || saving ? null : _load,
                child: const Text('Tentar novamente'),
              ),
            ],
            if (displayed.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Lista ainda não informada pelo responsável.'),
              ),
            for (final item in displayed.items)
              if (checklist == null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(
                    item.requiredItem ? 'Obrigatório' : 'Recomendado',
                  ),
                )
              else
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(item.name),
                  subtitle: Text(
                    item.requiredItem ? 'Obrigatório' : 'Recomendado',
                  ),
                  value: item.checked,
                  onChanged:
                      loading ||
                          saving ||
                          !displayed.editable ||
                          !BookingStatus.isActive(widget.booking.status)
                      ? null
                      : (value) => _save(item.id, value == true),
                ),
            if (checklist != null &&
                (!displayed.editable ||
                    !BookingStatus.isActive(widget.booking.status)))
              const Text(
                'Checklist disponível apenas para consulta nesta reserva.',
              ),
          ],
        ),
      ),
    );
  }
}
