class LocalGuide {
  LocalGuide({
    required this.id,
    required this.name,
    required this.email,
    required this.specialty,
    this.status = 'Convidado',
  });

  final String id;
  String name;
  String email;
  String specialty;
  String status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'specialty': specialty,
    'status': status,
  };

  factory LocalGuide.fromJson(Map<String, dynamic> json) {
    return LocalGuide(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Convidado',
    );
  }
}
