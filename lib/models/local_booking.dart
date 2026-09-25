class BookingStatus {
  const BookingStatus._();

  static const String pending = 'Pendente';
  static const String confirmed = 'Confirmado';
  static const String cancelled = 'Cancelado';

  static String normalize(String? value) {
    final raw = value?.trim() ?? '';

    if (raw.isEmpty) {
      return pending;
    }

    switch (raw.toLowerCase()) {
      case 'pendente':
      case 'pending':
        return pending;

      case 'confirmado':
      case 'confirmada':
      case 'confirmed':
        return confirmed;

      case 'cancelado':
      case 'cancelada':
      case 'cancelled':
      case 'canceled':
        return cancelled;

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

  static bool isCancelled(String? value) {
    return normalize(value) == cancelled;
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
  }) : _status = BookingStatus.normalize(status);

  final String id;
  final String trailId;
  String trailName;
  String personName;
  String date;
  String _status;
  String roleView;
  double valuePaid;

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
    );
  }
}
