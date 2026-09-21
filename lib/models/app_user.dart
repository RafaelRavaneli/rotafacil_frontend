class AppUser {
  AppUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.state,
    required this.role,
    this.document = '',
    this.profileImageDataUrl,
  });

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
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Turista',
      document: json['document']?.toString() ?? '',
      profileImageDataUrl: json['profileImageDataUrl']?.toString(),
    );
  }
}
