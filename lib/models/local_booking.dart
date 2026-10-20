class BookingStatus {
  const BookingStatus._();

  static const String pending = 'Aguardando confirmação';
  static const String confirmed = 'Confirmado';
  static const String cancelled = 'Cancelado';
  static const String rejected = 'Recusado';

  static String normalize(String? value) {
    final raw = value?.trim() ?? '';

    if (raw.isEmpty) {
      return pending;
    }

    switch (raw.toLowerCase()) {
      case 'pendente':
      case 'pending':
      case 'aguardando confirmação':
      case 'aguardando confirmacao':
        return pending;

      case 'confirmado':
      case 'confirmada':
      case 'agendado':
      case 'confirmed':
        return confirmed;

      case 'em_andamento':
        return 'Em andamento';
      case 'concluido':
      case 'concluído':
      case 'completed':
        return 'Concluído';
      case 'cancelado':
      case 'cancelada':
      case 'cancelled':
      case 'canceled':
        return cancelled;
      case 'recusado':
      case 'recusada':
      case 'rejected':
        return rejected;

      default:
        return raw;
    }
  }

  static bool isPending(String? value) {
    return normalize(value) == pending;
  }

  static bool isConfirmed(String? value) {
    return normalize(value) == confirmed;
  }

  static bool isActive(String? value) {
    final status = normalize(value);
    return status != cancelled && status != rejected && status != 'Concluído';
  }

  static bool canCancel(String? value) {
    final status = normalize(value);
    return status == pending || status == confirmed;
  }

  static bool isCancelled(String? value) {
    return normalize(value) == cancelled;
  }

  static bool isCompleted(String? value) {
    return normalize(value) == 'Concluído';
  }
}

class LocalBooking {
  LocalBooking({
    required this.id,
    required this.trailId,
    required this.trailName,
    required this.personName,
    required this.date,
    required String status,
    required this.roleView,
    this.valuePaid = 0,
    this.personId = '',
    this.guideId = '',
    this.departureId = '',
    this.startsAt = '',
    this.endsAt = '',
    this.createdAt,
    this.guidePhone = '',
    this.agencyId = '',
    this.agencyName = '',
    this.evaluated = false,
  }) : _status = BookingStatus.normalize(status);

  final String id;
  final String trailId;
  String trailName;
  String personName;
  String date;
  String _status;
  String roleView;
  double valuePaid;
  final String personId;
  final String guideId;
  final String departureId;
  final String startsAt;
  final String endsAt;
  final DateTime? createdAt;
  final String guidePhone;
  final String agencyId;
  final String agencyName;
  final bool evaluated;

  String get status => _status;

  set status(String value) {
    _status = BookingStatus.normalize(value);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trailId': trailId,
    'trailName': trailName,
    'personName': personName,
    'date': date,
    'status': status,
    'roleView': roleView,
    'valuePaid': valuePaid,
    'personId': personId,
    'guideId': guideId,
    'departureId': departureId,
    'startsAt': startsAt,
    'endsAt': endsAt,
    'createdAt': createdAt?.toIso8601String(),
    'guidePhone': guidePhone,
    'agencyId': agencyId,
    'agencyName': agencyName,
    'evaluated': evaluated,
  };

  factory LocalBooking.fromJson(Map<String, dynamic> json) {
    return LocalBooking(
      id: json['id']?.toString() ?? '',
      trailId: json['trailId']?.toString() ?? '',
      trailName: json['trailName']?.toString() ?? '',
      personName: json['personName']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? BookingStatus.pending,
      roleView: json['roleView']?.toString() ?? 'turista',
      valuePaid: (json['valuePaid'] as num?)?.toDouble() ?? 0,
      personId: (json['personId'] ?? json['id_usuario'])?.toString() ?? '',
      guideId: (json['guideId'] ?? json['id_guia'])?.toString() ?? '',
      departureId: (json['departureId'] ?? json['id_data'])?.toString() ?? '',
      startsAt:
          (json['startsAt'] ?? json['data_hora_inicio'])?.toString() ?? '',
      endsAt: (json['endsAt'] ?? json['data_hora_fim'])?.toString() ?? '',
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['criado_em'])?.toString() ?? '',
      ),
      guidePhone:
          (json['guidePhone'] ?? json['telefone_guia'])?.toString() ?? '',
      agencyId: (json['agencyId'] ?? json['id_agencia'])?.toString() ?? '',
      agencyName:
          (json['agencyName'] ?? json['nome_agencia'])?.toString() ?? '',
      evaluated: json['evaluated'] == true || json['avaliado'] == true,
    );
  }
}
