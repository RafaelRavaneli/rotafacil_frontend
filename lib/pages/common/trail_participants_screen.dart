import 'package:flutter/material.dart';

import '../../models/local_booking.dart';
import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_time_format.dart';

class TrailParticipantsScreen extends StatefulWidget {
  const TrailParticipantsScreen({super.key, required this.trail});

  final Trail trail;

  @override
  State<TrailParticipantsScreen> createState() =>
      _TrailParticipantsScreenState();
}

class _TrailParticipantsScreenState extends State<TrailParticipantsScreen> {
  String selectedDepartureId = 'all';

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  bool _matchesDeparture(LocalBooking booking, TrailDeparture departure) {
    if (booking.departureId.isNotEmpty) {
      return booking.departureId == departure.id;
    }
    return formatBrazilianDate(booking.date) ==
        formatBrazilianDate(_date(departure.startsAt));
  }

  @override
  Widget build(BuildContext context) {
    final departures = widget.trail.effectiveDepartures;
    return Scaffold(
      appBar: AppBar(title: const Text('Inscritos no roteiro')),
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
                  const SizedBox(height: 18),
                  if (visible.isEmpty)
                    const _EmptyParticipants()
                  else
                    ...visible.map(
                      (booking) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.green100,
                            child: Text(
                              booking.personName.trim().isEmpty
                                  ? '?'
                                  : booking.personName.trim()[0].toUpperCase(),
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
