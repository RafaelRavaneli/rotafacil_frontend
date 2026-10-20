import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../navigation/app_routes.dart';
import 'booking_details_screen.dart';

import '../../models/local_booking.dart';
import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_time_format.dart';
import '../../utils/run_action.dart';

class TrailParticipantsScreen extends StatefulWidget {
  const TrailParticipantsScreen({super.key, required this.trail});

  final Trail trail;

  @override
  State<TrailParticipantsScreen> createState() =>
      _TrailParticipantsScreenState();
}

class _TrailParticipantsScreenState extends State<TrailParticipantsScreen> {
  String selectedDepartureId = 'all';
  String? busyBookingId;
  bool finishing = false;

  Future<void> _goBack() async {
    if (await Navigator.maybePop(context)) return;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/roteiros');
  }

  Future<void> _contact(LocalBooking booking) async {
    var phone = booking.personPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.length == 10 || phone.length == 11) phone = '55$phone';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participante sem telefone cadastrado.')),
      );
      return;
    }
    await runAction(context, () async {
      final opened = await launchUrl(
        Uri.https('wa.me', '/$phone', {
          'text':
              'Olá, ${booking.personName}! Sobre sua reserva para ${widget.trail.name}.',
        }),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Não foi possível abrir o WhatsApp.');
    });
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  bool _matchesDeparture(LocalBooking booking, TrailDeparture departure) {
    if (booking.departureId.isNotEmpty) {
      return booking.departureId == departure.id;
    }
    return formatBrazilianDate(booking.date) ==
        formatBrazilianDate(_date(departure.startsAt));
  }

  Future<void> _respond(LocalBooking booking, String status) async {
    final action = status == 'confirmado' ? 'confirmar' : 'recusar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${action == 'confirmar' ? 'Confirmar' : 'Recusar'} reserva?',
        ),
        content: Text('Deseja $action a solicitação de ${booking.personName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action == 'confirmar' ? 'Confirmar' : 'Recusar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busyBookingId = booking.id);
    try {
      final saved = await runAction(
        context,
        () => AppStore.instance.respondBooking(booking, status),
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'confirmado'
                  ? 'Reserva confirmada.'
                  : 'Solicitação recusada.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busyBookingId = null);
    }
  }

  Future<void> _finish(TrailDeparture departure) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar esta saída?'),
        content: Text(
          'As reservas confirmadas de ${formatBrazilianDateTime(departure.startsAt)} serão concluídas e os participantes poderão avaliar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finalizar saída'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => finishing = true);
    try {
      final saved = await runAction(
        context,
        () => AppStore.instance.finishDeparture(
          trail: widget.trail,
          departure: departure,
        ),
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saída finalizada. Avaliações liberadas.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departures = widget.trail.effectiveDepartures;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _goBack),
        title: const Text('Inscritos no roteiro'),
      ),
      body: AnimatedBuilder(
        animation: AppStore.instance,
        builder: (context, _) {
          final allBookings = AppStore.instance.bookings
              .where(
                (booking) =>
                    booking.trailId == widget.trail.id &&
                    BookingStatus.isActive(booking.status),
              )
              .toList();
          final selected = departures
              .where((item) => item.id == selectedDepartureId)
              .firstOrNull;
          final visible = selected == null
              ? allBookings
              : allBookings
                    .where((booking) => _matchesDeparture(booking, selected))
                    .toList();
          visible.sort((a, b) => a.personName.compareTo(b.personName));

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Text(
                    widget.trail.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${visible.length} pessoa(s) inscrita(s)',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDepartureId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por data',
                      prefixIcon: Icon(Icons.date_range_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Todas as datas'),
                      ),
                      ...departures.map(
                        (departure) => DropdownMenuItem(
                          value: departure.id,
                          child: Text(
                            formatBrazilianDateTime(departure.startsAt),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedDepartureId = value ?? 'all'),
                  ),
                  if (selected != null &&
                      visible.any(
                        (booking) => BookingStatus.isConfirmed(booking.status),
                      )) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: finishing ? null : () => _finish(selected),
                      icon: const Icon(Icons.flag_circle_outlined),
                      label: Text(
                        finishing ? 'Finalizando...' : 'Finalizar esta saída',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (visible.isEmpty)
                    const _EmptyParticipants()
                  else
                    ...visible.map(
                      (booking) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.green100,
                                child: Text(
                                  booking.personName.trim().isEmpty
                                      ? '?'
                                      : booking.personName
                                            .trim()[0]
                                            .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.forest,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(booking.personName),
                              subtitle: Text(
                                '${formatBrazilianDate(booking.date)} • ${booking.status}',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _contact(booking),
                                    icon: const Icon(Icons.chat_outlined),
                                    label: const Text('Entrar em contato'),
                                  ),
                                  if (BookingStatus.isConfirmed(
                                        booking.status,
                                      ) ||
                                      BookingStatus.normalize(booking.status) ==
                                          'Em andamento')
                                    OutlinedButton.icon(
                                      onPressed: () => AppRoutes.push(
                                        context,
                                        AppRoutes.booking(booking.id),
                                        (_) => BookingDetailsScreen(
                                          bookingId: booking.id,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.receipt_long_outlined,
                                      ),
                                      label: const Text('Detalhes da reserva'),
                                    ),
                                ],
                              ),
                            ),
                            if (BookingStatus.isPending(booking.status))
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: busyBookingId == null
                                            ? () =>
                                                  _respond(booking, 'recusado')
                                            : null,
                                        child: const Text('Recusar'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: busyBookingId == null
                                            ? () => _respond(
                                                booking,
                                                'confirmado',
                                              )
                                            : null,
                                        child: Text(
                                          busyBookingId == booking.id
                                              ? 'Salvando...'
                                              : 'Confirmar',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
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
}

class _EmptyParticipants extends StatelessWidget {
  const _EmptyParticipants();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(Icons.group_off_outlined, size: 52, color: AppColors.muted),
          SizedBox(height: 12),
          Text(
            'Nenhuma pessoa inscrita nesta data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
