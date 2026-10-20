import 'package:flutter/material.dart';

import '../../models/local_booking.dart';
import '../../models/trail.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/trail_schedule.dart';
import '../../widgets/backend_refresh.dart';
import '../../widgets/booking_summary_card.dart';
import '../../widgets/scheduled_trail_card.dart';
import '../../navigation/app_routes.dart';
import 'booking_details_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key, required this.role, this.onRefresh});

  final String role;
  final Future<void> Function()? onRefresh;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  DateTime visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTimeRange? period;

  bool get isTourist => widget.role.toLowerCase() == 'turista';

  DateTime? _parseDate(String value) {
    final short = value.trim().split(' ').first;
    final iso = DateTime.tryParse(short);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = short.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  Trail? _trailFor(LocalBooking booking, List<Trail> trails) {
    for (final trail in trails) {
      if (trail.id == booking.trailId) return trail;
    }
    return null;
  }

  DateTimeRange? _bookingRange(LocalBooking booking, List<Trail> trails) {
    final trail = _trailFor(booking, trails);
    final start =
        DateTime.tryParse(booking.startsAt) ??
        _parseDate(booking.date) ??
        trail?.startsAt;
    if (start == null) return null;
    final end = DateTime.tryParse(booking.endsAt) ?? start;
    return DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day),
    );
  }

  bool _overlaps(DateTimeRange value, DateTimeRange filter) {
    return !value.end.isBefore(filter.start) &&
        !value.start.isAfter(filter.end);
  }

  DateTimeRange _departureRange(TrailDeparture departure) => DateTimeRange(
    start: DateTime(
      departure.startsAt.year,
      departure.startsAt.month,
      departure.startsAt.day,
    ),
    end: DateTime(
      departure.endsAt.year,
      departure.endsAt.month,
      departure.endsAt.day,
    ),
  );

  Set<DateTime> _markedTrailDays(List<ScheduledTrail> schedule) {
    final days = <DateTime>{};
    for (final item in schedule) {
      final range = _departureRange(item.departure);
      var day = range.start;
      while (!day.isAfter(range.end)) {
        days.add(day);
        day = day.add(const Duration(days: 1));
      }
    }
    return days;
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: period,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 10),
      helpText: 'Filtrar agenda por período',
      saveText: 'Aplicar',
    );
    if (selected == null) return;
    setState(() {
      period = selected;
      visibleMonth = DateTime(selected.start.year, selected.start.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return BackendRefresh(
      onRefresh: widget.onRefresh,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final normalized = widget.role.toLowerCase();
            final allBookings = store.bookings.where((booking) {
              if (normalized == 'turista') return booking.roleView == 'turista';
              if (normalized == 'guia') {
                return booking.roleView == 'guia' ||
                    booking.roleView == 'turista';
              }
              return true;
            }).toList();
            final visibleBookings = period == null
                ? allBookings
                : allBookings.where((booking) {
                    final range = _bookingRange(booking, store.trails);
                    return range != null && _overlaps(range, period!);
                  }).toList();
            final activeBookings = visibleBookings
                .where((booking) => BookingStatus.isActive(booking.status))
                .toList();
            final historyBookings = visibleBookings
                .where((booking) => !BookingStatus.isActive(booking.status))
                .toList();
            final schedule = upcomingTrailSchedule(store.managedTrails);
            final visibleSchedule = period == null
                ? schedule
                : schedule
                      .where(
                        (item) =>
                            _overlaps(_departureRange(item.departure), period!),
                      )
                      .toList();

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                  children: [
                    Text(
                      isTourist ? 'Minhas reservas' : 'Agenda',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isTourist
                          ? 'Acompanhe seus roteiros e consulte cada reserva.'
                          : 'Veja os próximos roteiros e filtre por período.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    if (!isTourist) ...[
                      const SizedBox(height: 20),
                      _AgendaCalendar(
                        month: visibleMonth,
                        markedDays: _markedTrailDays(schedule),
                        selectedPeriod: period,
                        onPrevious: () => setState(() {
                          visibleMonth = DateTime(
                            visibleMonth.year,
                            visibleMonth.month - 1,
                          );
                        }),
                        onNext: () => setState(() {
                          visibleMonth = DateTime(
                            visibleMonth.year,
                            visibleMonth.month + 1,
                          );
                        }),
                        onDaySelected: (day) => setState(() {
                          period = DateTimeRange(start: day, end: day);
                        }),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickPeriod,
                              icon: const Icon(Icons.date_range_outlined),
                              label: Text(
                                period == null
                                    ? 'Filtrar período'
                                    : '${_dateLabel(period!.start)} a ${_dateLabel(period!.end)}',
                              ),
                            ),
                          ),
                          if (period != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Limpar período',
                              onPressed: () => setState(() => period = null),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        period == null
                            ? 'Próximos roteiros'
                            : 'Roteiros do período',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (isTourist && visibleBookings.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Nenhum agendamento neste período.'),
                        ),
                      ),
                    if (!isTourist && visibleSchedule.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Nenhum roteiro futuro neste período.'),
                        ),
                      ),
                    if (!isTourist)
                      ...visibleSchedule.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ScheduledTrailCard(
                            trail: item.trail,
                            departure: item.departure,
                          ),
                        ),
                      ),
                    if (isTourist && activeBookings.isNotEmpty) ...[
                      const Text(
                        'Reservas ativas',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (isTourist)
                      ...activeBookings.map(
                        (booking) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BookingSummaryCard(
                            booking: booking,
                            onTap: () => AppRoutes.push(
                              context,
                              AppRoutes.booking(booking.id),
                              (_) =>
                                  BookingDetailsScreen(bookingId: booking.id),
                            ),
                          ),
                        ),
                      ),
                    if (isTourist && historyBookings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Histórico',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (isTourist)
                      ...historyBookings.map(
                        (booking) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BookingSummaryCard(
                            booking: booking,
                            onTap: () => AppRoutes.push(
                              context,
                              AppRoutes.booking(booking.id),
                              (_) =>
                                  BookingDetailsScreen(bookingId: booking.id),
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
      ),
    );
  }
}

class _AgendaCalendar extends StatelessWidget {
  const _AgendaCalendar({
    required this.month,
    required this.markedDays,
    required this.selectedPeriod,
    required this.onPrevious,
    required this.onNext,
    required this.onDaySelected,
  });

  final DateTime month;
  final Set<DateTime> markedDays;
  final DateTimeRange? selectedPeriod;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDaySelected;

  static const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _selected(DateTime day) {
    final value = selectedPeriod;
    return value != null &&
        !day.isBefore(value.start) &&
        !day.isAfter(value.end);
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final offset = first.weekday % 7;
    final gridStart = first.subtract(Duration(days: offset));
    final today = DateTime.now();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mês anterior',
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '${months[month.month - 1]} ${month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo mês',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Row(
              children: [
                for (final label in ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.08,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final day = gridStart.add(Duration(days: index));
                final inMonth = day.month == month.month;
                final marked = markedDays.any((value) => _sameDay(value, day));
                final selected = _selected(day);
                final isToday = _sameDay(day, today);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onDaySelected(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.green700 : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !selected
                          ? Border.all(color: AppColors.green700)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : inMonth
                                ? AppColors.ink
                                : AppColors.muted.withValues(alpha: 0.45),
                            fontWeight: marked || isToday
                                ? FontWeight.w900
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: marked
                                ? selected
                                      ? Colors.white
                                      : AppColors.green700
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.green700),
                SizedBox(width: 6),
                Text(
                  'Dia com roteiro agendado',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
