DateTime? parseAppDateTime(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;
  final iso = DateTime.tryParse(raw);
  if (iso != null) return iso;
  final match = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\D+(\d{1,2}):(\d{2}))?',
  ).firstMatch(raw);
  if (match == null) return null;
  return DateTime(
    int.parse(match[3]!),
    int.parse(match[2]!),
    int.parse(match[1]!),
    int.tryParse(match[4] ?? '') ?? 0,
    int.tryParse(match[5] ?? '') ?? 0,
  );
}

String formatBrazilianDate(String? value, {String fallback = ''}) {
  final date = parseAppDateTime(value);
  if (date == null) return fallback.isNotEmpty ? fallback : value?.trim() ?? '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String formatBrazilianDateTime(DateTime? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final date = formatBrazilianDate(value.toIso8601String());
  final time =
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
  return '$date às $time';
}
