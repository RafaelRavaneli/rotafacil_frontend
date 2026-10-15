class Availability {
  const Availability({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.note,
    this.capacity,
  });

  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String type;
  final String note;
  final int? capacity;

  bool get blocked => type == 'bloqueio';

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
    id: json['id']?.toString() ?? '',
    date: json['data']?.toString() ?? '',
    startTime: json['horario_inicio']?.toString() ?? '',
    endTime: json['horario_fim']?.toString() ?? '',
    type: json['tipo']?.toString() ?? 'disponivel',
    note: json['observacao']?.toString() ?? '',
    capacity: int.tryParse(json['capacidade']?.toString() ?? ''),
  );
}
