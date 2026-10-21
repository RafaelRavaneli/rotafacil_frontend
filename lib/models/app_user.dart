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
    this.emailConfirmed = false,
    this.cadasturNumber = '',
    this.cadasturValidUntil = '',
    this.profileImageDataUrl,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelation = '',
    this.emergencyContactConsent = false,
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
  bool emailConfirmed;
  String cadasturNumber;
  String cadasturValidUntil;
  String? profileImageDataUrl;
  String emergencyContactName;
  String emergencyContactPhone;
  String emergencyContactRelation;
  bool emergencyContactConsent;
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
    'emailConfirmed': emailConfirmed,
    'cadasturNumber': cadasturNumber,
    'cadasturValidUntil': cadasturValidUntil,
    'profileImageDataUrl': profileImageDataUrl,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'emergencyContactRelation': emergencyContactRelation,
    'emergencyContactConsent': emergencyContactConsent,
    'professionalDescription': professionalDescription,
    'specialties': specialties,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: (json['name'] ?? json['nome'])?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      emailConfirmed:
          json['email_confirmado'] == true || json['emailConfirmed'] == true,
      phone: (json['phone'] ?? json['telefone'])?.toString() ?? '',
      city: (json['city'] ?? json['cidade'])?.toString() ?? '',
      state: (json['state'] ?? json['estado'])?.toString() ?? '',
      role: (json['role'] ?? json['tipo'])?.toString() ?? 'Turista',
      document: (json['document'] ?? json['documento'])?.toString() ?? '',
      cadasturNumber:
          (json['cadasturNumber'] ?? json['cadastur_numero'])?.toString() ?? '',
      cadasturValidUntil:
          (json['cadasturValidUntil'] ?? json['cadastur_validade'])
              ?.toString() ??
          '',
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
      emergencyContactRelation:
          (json['emergencyContactRelation'] ??
                  json['contato_emergencia_relacao'])
              ?.toString() ??
          '',
      emergencyContactConsent:
          json['emergencyContactConsent'] == true ||
          json['contato_emergencia_consentimento'] == true,
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
