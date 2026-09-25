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
  }) : role = normalizeAppUserRole(role);

  String name;
  String email;
  String phone;
  String city;
  String state;
  String role;
  String document;
  String? profileImageDataUrl;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'city': city,
    'state': state,
    'role': role,
    'document': document,
    'profileImageDataUrl': profileImageDataUrl,
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
    );
  }
}
