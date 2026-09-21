class LocalBooking {
  LocalBooking({
    required this.id,
    required this.trailId,
    required this.trailName,
    required this.personName,
    required this.date,
    required this.status,
    required this.roleView,
    this.valuePaid = 0,
  });

  final String id;
  final String trailId;
  String trailName;
  String personName;
  String date;
  String status;
  String roleView;
  double valuePaid;

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
      status: json['status']?.toString() ?? 'Pendente',
      roleView: json['roleView']?.toString() ?? 'turista',
      valuePaid: (json['valuePaid'] as num?)?.toDouble() ?? 0,
    );
  }
}
