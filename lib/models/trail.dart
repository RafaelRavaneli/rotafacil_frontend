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
    required this.date,
    this.price = 189,
    this.status = 'Ativa',
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
  final String guideName;
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
        'date': date,
        'price': price,
        'status': status,
        'modality': modality,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory Trail.fromJson(Map<String, dynamic> json) {
    return Trail(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['nome'])?.toString() ?? '',
      city: (json['city'] ?? json['cidade'])?.toString() ?? '',
      state: (json['state'] ?? json['estado'])?.toString() ?? '',
      difficulty:
          (json['difficulty'] ?? json['dificuldade'])?.toString() ??
              'Moderada',
      distanceKm:
          ((json['distanceKm'] ?? json['distancia_km']) as num?)
                  ?.toDouble() ??
              0,
      duration: json['duration']?.toString() ?? '3h',
      elevation: (json['elevation'] as num?)?.toInt() ?? 0,
      bestSeason: json['bestSeason']?.toString() ?? 'Ano todo',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      description:
          (json['description'] ?? json['descricao'])?.toString() ?? '',
      imageUrl:
          (json['imageUrl'] ?? json['imagem_url'])?.toString() ?? '',
      guideName:
          (json['guideName'] ?? json['id_guia'])?.toString() ??
              'Guia responsável',
      date: (json['date'] ?? json['data_atividade'])?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'Ativa',
      modality:
          (json['modality'] ?? json['modalidade'])?.toString() ??
              'Trekking',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
