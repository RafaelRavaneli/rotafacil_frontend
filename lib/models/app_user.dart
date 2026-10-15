import '../utils/role_utils.dart';

String normalizeAppUserRole(String? value) => roleDisplayName(value);

class AppUser {
  AppUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.state,
    required String role,
    this.document = '',
    this.profileImageDataUrl,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.professionalDescription = '',
    this.specialties = const [],
  }) : role = normalizeAppUserRole(role);

  String name;
  String email;
  String phone;
  String city;
  String state;
  String role;
  String document;
  String? profileImageDataUrl;
  String emergencyContactName;
  String emergencyContactPhone;
  String professionalDescription;
  List<String> specialties;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'city': city,
    'state': state,
    'role': role,
    'document': document,
    'profileImageDataUrl': profileImageDataUrl,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'professionalDescription': professionalDescription,
    'specialties': specialties,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: (json['name'] ?? json['nome'])?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: (json['phone'] ?? json['telefone'])?.toString() ?? '',
      city: (json['city'] ?? json['cidade'])?.toString() ?? '',
      state: (json['state'] ?? json['estado'])?.toString() ?? '',
      role: (json['role'] ?? json['tipo'])?.toString() ?? 'Turista',
      document: (json['document'] ?? json['documento'])?.toString() ?? '',
      profileImageDataUrl: (json['profileImageDataUrl'] ?? json['foto_url'])
          ?.toString(),
      emergencyContactName:
          (json['emergencyContactName'] ?? json['contato_emergencia_nome'])
              ?.toString() ??
          '',
      emergencyContactPhone:
          (json['emergencyContactPhone'] ?? json['contato_emergencia_telefone'])
              ?.toString() ??
          '',
      professionalDescription:
          (json['professionalDescription'] ?? json['descricao_profissional'])
              ?.toString() ??
          '',
      specialties: (json['specialties'] ?? json['especialidades']) is List
          ? List<String>.from(
              (json['specialties'] ?? json['especialidades']) as List,
            )
          : const [],
    );
  }
}
