import '../models/trail.dart';

class ScheduledTrail {
  const ScheduledTrail({required this.trail, required this.departure});

  final Trail trail;
  final TrailDeparture departure;
}

List<ScheduledTrail> upcomingTrailSchedule(
  Iterable<Trail> trails, {
  DateTime? now,
  DateTime? through,
}) {
  final reference = now ?? DateTime.now();
  final result = <ScheduledTrail>[];

  for (final trail in trails) {
    if (!TrailStatus.isActive(trail.status) || trail.archived) continue;
    for (final departure in trail.effectiveDepartures) {
      if (departure.startsAt.isBefore(reference)) continue;
      if (through != null && departure.startsAt.isAfter(through)) continue;
      result.add(ScheduledTrail(trail: trail, departure: departure));
    }
  }

  result.sort((a, b) => a.departure.startsAt.compareTo(b.departure.startsAt));
  return result;
}

List<ScheduledTrail> upcomingTrailsOnce(
  Iterable<Trail> trails, {
  DateTime? now,
  DateTime? through,
}) {
  final schedule = upcomingTrailSchedule(trails, now: now, through: through);
  final seen = <String>{};
  return schedule.where((item) => seen.add(item.trail.id)).toList();
}
