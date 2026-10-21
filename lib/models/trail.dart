import 'trail_accessibility.dart';

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

class TrailDifficulty {
  const TrailDifficulty._();

  static const String beginner = 'Iniciante';
  static const String intermediate = 'Intermediário';
  static const String advanced = 'Avançado';
  static const List<String> values = [beginner, intermediate, advanced];

  static String normalize(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'fácil':
      case 'facil':
      case 'iniciante':
        return beginner;
      case 'moderada':
      case 'moderado':
      case 'intermediário':
      case 'intermediario':
        return intermediate;
      case 'difícil':
      case 'dificil':
      case 'avançado':
      case 'avancado':
        return advanced;
      default:
        return intermediate;
    }
  }
}

class RouteActivity {
  const RouteActivity._();

  static const List<String> values = [
    'Trilha',
    'Trekking',
    'Aquatrekking',
    'Escalada',
    'Rapel',
    'Tirolesa',
    'Rafting',
    'Boia cross',
    'Acampamento',
    'Canoagem',
    'Caiaque',
    'Canyoning',
    'Cachoeirismo',
    'Mountain bike',
    'Cicloturismo',
    'Arvorismo',
    'Via ferrata',
    'Cavalgada',
    'Observação de aves',
    'Observação de fauna',
    'Passeio ecológico',
    'Espeleologia',
    'Orientação',
    'Mergulho',
    'Stand up paddle',
    'Surfe',
    'Pesca esportiva',
    'Sandboard',
    'Voo livre',
    'Parapente',
    'Asa-delta',
    'Off-road',
  ];
}

class TrailPoint {
  const TrailPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory TrailPoint.fromJson(Map<String, dynamic> json) => TrailPoint(
    latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
    longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
  );
}

class TrailDeparture {
  const TrailDeparture({
    required this.id,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'data_hora_inicio': startsAt.toIso8601String(),
    'data_hora_fim': endsAt.toIso8601String(),
  };

  factory TrailDeparture.fromJson(Map<String, dynamic> json) {
    final startsAt = DateTime.parse(
      (json['data_hora_inicio'] ?? json['startDateTime']).toString(),
    );
    final endsAt = DateTime.parse(
      (json['data_hora_fim'] ?? json['endDateTime']).toString(),
    );
    return TrailDeparture(
      id: json['id']?.toString() ?? '',
      startsAt: startsAt,
      endsAt: endsAt,
    );
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
    this.responsibleRole = '',
    this.createdBy = '',
    required this.date,
    this.price = 189,
    this.status = TrailStatus.active,
    this.archived = false,
    this.modality = 'Trilha',
    this.activities = const [],
    this.latitude,
    this.longitude,
    this.meetingPoint = '',
    this.organizerEmergencyPhone = '',
    this.emergencyInstructions = '',
    this.accessible = false,
    this.accessibility = const TrailAccessibility(),
    this.recommendedItems = const [],
    this.requiredItems = const [],
    this.route = const [],
    this.capacity = 12,
    this.startTime = '',
    this.endTime = '',
    this.endDate = '',
    this.startDateTime = '',
    this.endDateTime = '',
    this.departures = const [],
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
  final String responsibleRole;
  final String createdBy;

  final String date;
  final double price;
  final String status;
  final bool archived;
  final String modality;
  final List<String> activities;
  final double? latitude;
  final double? longitude;
  final String meetingPoint;
  final String organizerEmergencyPhone;
  final String emergencyInstructions;
  final bool accessible;
  final TrailAccessibility accessibility;
  final List<String> recommendedItems;
  final List<String> requiredItems;
  final List<TrailPoint> route;
  final int capacity;
  final String startTime;
  final String endTime;
  final String endDate;
  final String startDateTime;
  final String endDateTime;
  final List<TrailDeparture> departures;

  List<String> get effectiveActivities => activities.isNotEmpty
      ? List.unmodifiable(activities)
      : [modality.trim().isEmpty ? 'Trilha' : modality];

  List<TrailDeparture> get effectiveDepartures {
    if (departures.isNotEmpty) return List.unmodifiable(departures);
    final start =
        DateTime.tryParse(startDateTime) ??
        _combineDateAndTime(date, startTime);
    final end =
        DateTime.tryParse(endDateTime) ??
        _combineDateAndTime(endDate.isEmpty ? date : endDate, endTime);
    if (start == null || end == null) return const [];
    return [TrailDeparture(id: 'legacy-$id', startsAt: start, endsAt: end)];
  }

  DateTime? get startsAt =>
      effectiveDepartures.isEmpty ? null : effectiveDepartures.first.startsAt;

  DateTime? get endsAt =>
      effectiveDepartures.isEmpty ? null : effectiveDepartures.first.endsAt;

  String get location => '$city - $state';

  bool get hasDistance => distanceKm.isFinite && distanceKm > 0;
  String get distanceLabel {
    if (!hasDistance) return 'Distância não informada';
    return '${distanceKm.toString().replaceFirst(RegExp(r"\.0$"), "").replaceAll(".", ",")} km';
  }

  String get responsibleName =>
      guideName.trim().isEmpty || guideName == 'Guia responsável'
      ? 'Responsável não informado'
      : guideName;

  static double parseDistance(Object? value) {
    final distance = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().trim().replaceAll(',', '.') ?? '');
    return distance != null && distance.isFinite && distance > 0 ? distance : 0;
  }

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
    'responsibleRole': responsibleRole,
    'createdBy': createdBy,
    'date': date,
    'price': price,
    'status': status,
    'archived': archived,
    'modality': modality,
    'activities': activities,
    'latitude': latitude,
    'longitude': longitude,
    'meetingPoint': meetingPoint,
    'emergencia_organizador_telefone': organizerEmergencyPhone,
    'emergencia_instrucoes': emergencyInstructions,
    'accessible': accessible,
    'acessibilidade': accessibility.toJson(),
    'recommendedItems': recommendedItems,
    'requiredItems': requiredItems,
    'route': route.map((point) => point.toJson()).toList(),
    'capacity': capacity,
    'startTime': startTime,
    'endTime': endTime,
    'endDate': endDate,
    'startDateTime': startDateTime,
    'endDateTime': endDateTime,
    'departures': departures.map((item) => item.toJson()).toList(),
  };

  factory Trail.fromJson(Map<String, dynamic> json) {
    final rawDistance = json['distanceKm'] ?? json['distancia_km'];

    final rawPrice = json['price'] ?? json['preco'];

    final rawElevation = json['elevation'];

    final rawRating = json['rating'] ?? json['nota_media'];

    final rawReviews = json['reviews'] ?? json['total_avaliacoes'];

    final rawItems = json['recommendedItems'] ?? json['itens_recomendados'];
    final rawRequiredItems =
        json['requiredItems'] ?? json['itens_obrigatorios'];
    final rawRoute = json['route'] ?? json['trajeto'];
    final rawActivities = json['activities'] ?? json['atividades'];
    final rawDepartures = json['departures'] ?? json['datas'];
    final legacyModality =
        (json['modality'] ?? json['modalidade'])?.toString() ?? 'Trilha';

    return Trail(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['nome'])?.toString() ?? '',
      city: (json['city'] ?? json['cidade'])?.toString() ?? '',
      state: (json['state'] ?? json['estado'])?.toString() ?? '',
      difficulty: TrailDifficulty.normalize(
        (json['difficulty'] ?? json['dificuldade'])?.toString(),
      ),
      distanceKm: parseDistance(rawDistance),
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
      guideName:
          (json['guideName'] ?? json['nome_guia'])?.toString() ??
          'Guia responsável',

      guideId: (json['guideId'] ?? json['id_guia'])?.toString() ?? '',
      responsibleRole:
          (json['responsibleRole'] ?? json['tipo_responsavel'])?.toString() ??
          '',
      createdBy: (json['createdBy'] ?? json['criado_por'])?.toString() ?? '',

      date: (json['date'] ?? json['data_atividade'])?.toString() ?? '',
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ?? 0,
      status: json['ativo'] == false
          ? TrailStatus.inactive
          : TrailStatus.normalize(json['status']?.toString()),
      archived: json['archived'] == true || json['arquivado'] == true,
      modality: legacyModality,
      activities: rawActivities is List
          ? rawActivities.map((item) => item.toString()).toList()
          : [legacyModality],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      meetingPoint:
          (json['meetingPoint'] ?? json['ponto_encontro'])?.toString() ?? '',
      organizerEmergencyPhone:
          json['emergencia_organizador_telefone']?.toString() ?? '',
      emergencyInstructions: json['emergencia_instrucoes']?.toString() ?? '',
      accessible: json['accessible'] == true || json['acessivel'] == true,
      accessibility: TrailAccessibility.fromJson(json['acessibilidade']),
      recommendedItems: rawItems is List
          ? rawItems.map((item) => item.toString()).toList()
          : const [],
      requiredItems: rawRequiredItems is List
          ? rawRequiredItems.whereType<String>().toList()
          : const [],
      route: rawRoute is List
          ? rawRoute
                .whereType<Map>()
                .map(
                  (point) =>
                      TrailPoint.fromJson(Map<String, dynamic>.from(point)),
                )
                .toList()
          : const [],
      capacity:
          int.tryParse(
            (json['capacity'] ?? json['capacidade'])?.toString() ?? '',
          ) ??
          12,
      startTime:
          (json['startTime'] ?? json['horario_inicio'])?.toString() ?? '',
      endTime: (json['endTime'] ?? json['horario_fim'])?.toString() ?? '',
      endDate: (json['endDate'] ?? json['data_fim'])?.toString() ?? '',
      startDateTime:
          (json['startDateTime'] ?? json['data_hora_inicio'])?.toString() ?? '',
      endDateTime:
          (json['endDateTime'] ?? json['data_hora_fim'])?.toString() ?? '',
      departures: rawDepartures is List
          ? rawDepartures
                .whereType<Map>()
                .map(
                  (item) =>
                      TrailDeparture.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  static DateTime? _combineDateAndTime(String dateValue, String timeValue) {
    if (dateValue.trim().isEmpty) return null;
    final parts = dateValue.trim().split('/');
    final normalizedDate = parts.length == 3
        ? '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}'
        : dateValue.trim().split(' ').first;
    final normalizedTime = timeValue.trim().isEmpty
        ? '00:00'
        : timeValue.trim();
    return DateTime.tryParse('${normalizedDate}T$normalizedTime');
  }
}
