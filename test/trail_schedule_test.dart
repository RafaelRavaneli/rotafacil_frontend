import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/utils/trail_schedule.dart';

Trail routeWithDates({
  required String id,
  required List<TrailDeparture> departures,
  String status = TrailStatus.active,
  bool archived = false,
}) => Trail.fromJson({
  'id': id,
  'nome': 'Roteiro $id',
  'cidade': 'Maringá',
  'estado': 'PR',
  'status': status,
  'arquivado': archived,
  'datas': departures.map((item) => item.toJson()).toList(),
});

TrailDeparture departure(String id, DateTime start) => TrailDeparture(
  id: id,
  startsAt: start,
  endsAt: start.add(const Duration(hours: 4)),
);

void main() {
  final now = DateTime(2026, 10, 20, 10);

  test('agenda inclui somente datas futuras de roteiros ativos', () {
    final route = routeWithDates(
      id: '1',
      departures: [
        departure('past', now.subtract(const Duration(days: 1))),
        departure('future', now.add(const Duration(days: 2))),
      ],
    );
    final inactive = routeWithDates(
      id: '2',
      status: TrailStatus.inactive,
      departures: [departure('inactive', now.add(const Duration(days: 3)))],
    );

    final result = upcomingTrailSchedule([route, inactive], now: now);

    expect(result.map((item) => item.departure.id), ['future']);
  });

  test('painel limita 30 dias e exibe roteiro uma vez', () {
    final route = routeWithDates(
      id: '1',
      departures: [
        departure('first', now.add(const Duration(days: 5))),
        departure('second', now.add(const Duration(days: 10))),
      ],
    );
    final later = routeWithDates(
      id: '2',
      departures: [departure('later', now.add(const Duration(days: 31)))],
    );

    final result = upcomingTrailsOnce(
      [route, later],
      now: now,
      through: now.add(const Duration(days: 30)),
    );

    expect(result, hasLength(1));
    expect(result.single.departure.id, 'first');
  });
}
