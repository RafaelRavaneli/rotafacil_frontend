class GuideProfile {
  const GuideProfile({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.bio,
    required this.specialties,
    required this.experienceYears,
    required this.completedTrails,
    required this.totalKm,
    required this.city,
    required this.state,
    this.status = 'Aprovado',
    this.verified = true,
  });

  final String id;
  final String name;
  final double rating;
  final int reviews;
  final String imageUrl;
  final String bio;
  final List<String> specialties;
  final int experienceYears;
  final int completedTrails;
  final double totalKm;
  final String city;
  final String state;
  final String status;
  final bool verified;

  String get location => '$city - $state';

  factory GuideProfile.fromJson(Map<String, dynamic> json) {
    final rawSpecialties = json['especialidades'] ?? json['specialties'];
    return GuideProfile(
      id: json['id']?.toString() ?? '',
      name: (json['nome'] ?? json['name'])?.toString() ?? 'Guia',
      rating:
          double.tryParse('${json['nota_media'] ?? json['rating'] ?? 0}') ?? 0,
      reviews:
          int.tryParse('${json['total_avaliacoes'] ?? json['reviews'] ?? 0}') ??
          0,
      imageUrl: (json['foto_url'] ?? json['imageUrl'])?.toString() ?? '',
      bio: (json['descricao_profissional'] ?? json['bio'])?.toString() ?? '',
      specialties: rawSpecialties is List
          ? rawSpecialties
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
      experienceYears: 0,
      completedTrails: 0,
      totalKm: 0,
      city: (json['cidade'] ?? json['city'])?.toString() ?? '',
      state: (json['estado'] ?? json['state'])?.toString() ?? '',
      verified: json['verificado'] == true || json['verified'] == true,
    );
  }
}
