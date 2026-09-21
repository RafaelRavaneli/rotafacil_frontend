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
}
