class TrailStatus {
  const TrailStatus._();

  static const String active = 'Ativa';
  static const String draft = 'Rascunho';
  static const String inactive = 'Inativa';

  static String normalize(String? value) {
    final raw = value?.trim() ?? '';

    if (raw.isEmpty) {
      return active;
    }

    switch (raw.toLowerCase()) {
      case 'ativa':
      case 'ativo':
      case 'active':
        return active;

      case 'rascunho':
      case 'draft':
        return draft;

      case 'inativa':
      case 'inativo':
      case 'inactive':
        return inactive;

      default:
        return raw;
    }
  }

  static bool isActive(String? value) {
    return normalize(value) == active;
  }

  static bool isDraft(String? value) {
    return normalize(value) == draft;
  }

  static bool isInactive(String? value) {
    return normalize(value) == inactive;
  }
}

class Trail {
  const Trail({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.difficulty,
    required this.distanceKm,
    required this.duration,
    required this.elevation,
    required this.bestSeason,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.imageUrl,
    required this.guideName,
    this.guideId = '',
    required this.date,
    this.price = 189,
    this.status = TrailStatus.active,
    this.modality = 'Trekking',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final String difficulty;
  final double distanceKm;
  final String duration;
  final int elevation;
  final String bestSeason;
  final double rating;
  final int reviews;
  final String description;
  final String imageUrl;

  /// Nome exibido na interface.
  final String guideName;

  /// Identificador do guia usado na integração com o backend.
  final String guideId;

  final String date;
  final double price;
  final String status;
  final String modality;
  final double? latitude;
  final double? longitude;

  String get location => '$city - $state';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'state': state,
    'difficulty': difficulty,
    'distanceKm': distanceKm,
    'duration': duration,
    'elevation': elevation,
    'bestSeason': bestSeason,
    'rating': rating,
    'reviews': reviews,
    'description': description,
    'imageUrl': imageUrl,
    'guideName': guideName,
    'guideId': guideId,
    'date': date,
    'price': price,
    'status': status,
    'modality': modality,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory Trail.fromJson(Map<String, dynamic> json) {
    final rawDistance = json['distanceKm'] ?? json['distancia_km'];

    final rawPrice = json['price'];

    final rawElevation = json['elevation'];

    final rawRating = json['rating'];

    final rawReviews = json['reviews'];

    return Trail(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['nome'])?.toString() ?? '',
      city: (json['city'] ?? json['cidade'])?.toString() ?? '',
      state: (json['state'] ?? json['estado'])?.toString() ?? '',
      difficulty:
          (json['difficulty'] ?? json['dificuldade'])?.toString() ?? 'Moderada',
      distanceKm: rawDistance is num
          ? rawDistance.toDouble()
          : double.tryParse(rawDistance?.toString() ?? '') ?? 0,
      duration: json['duration']?.toString() ?? '3h',
      elevation: rawElevation is num
          ? rawElevation.toInt()
          : int.tryParse(rawElevation?.toString() ?? '') ?? 0,
      bestSeason: json['bestSeason']?.toString() ?? 'Ano todo',
      rating: rawRating is num
          ? rawRating.toDouble()
          : double.tryParse(rawRating?.toString() ?? '') ?? 0,
      reviews: rawReviews is num
          ? rawReviews.toInt()
          : int.tryParse(rawReviews?.toString() ?? '') ?? 0,
      description: (json['description'] ?? json['descricao'])?.toString() ?? '',
      imageUrl: (json['imageUrl'] ?? json['imagem_url'])?.toString() ?? '',

      // Nome e ID agora são campos separados.
      guideName: json['guideName']?.toString() ?? 'Guia responsável',

      guideId: (json['guideId'] ?? json['id_guia'])?.toString() ?? '',

      date: (json['date'] ?? json['data_atividade'])?.toString() ?? '',
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ?? 0,
      status: TrailStatus.normalize(json['status']?.toString()),
      modality:
          (json['modality'] ?? json['modalidade'])?.toString() ?? 'Trekking',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
