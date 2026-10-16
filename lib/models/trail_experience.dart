class TrailReview {
  const TrailReview({
    required this.userName,
    required this.rating,
    required this.comment,
  });

  final String userName;
  final int rating;
  final String comment;

  factory TrailReview.fromJson(Map<String, dynamic> json) => TrailReview(
    userName: json['nome_usuario']?.toString() ?? 'Participante',
    rating: int.tryParse(json['nota']?.toString() ?? '') ?? 0,
    comment: json['comentario']?.toString() ?? '',
  );
}

class TrailWeather {
  const TrailWeather({
    required this.date,
    required this.condition,
    this.minimumTemperature,
    this.maximumTemperature,
    this.rainProbability,
  });

  final String date;
  final String condition;
  final double? minimumTemperature;
  final double? maximumTemperature;
  final int? rainProbability;

  factory TrailWeather.fromJson(Map<String, dynamic> json) => TrailWeather(
    date: json['data']?.toString() ?? '',
    condition: json['condicao']?.toString() ?? 'Condição não informada',
    minimumTemperature: double.tryParse(
      json['temperatura_minima']?.toString() ?? '',
    ),
    maximumTemperature: double.tryParse(
      json['temperatura_maxima']?.toString() ?? '',
    ),
    rainProbability: int.tryParse(
      json['probabilidade_chuva']?.toString() ?? '',
    ),
  );
}

class EmergencyContact {
  const EmergencyContact({
    required this.participantName,
    required this.participantPhone,
    required this.contactName,
    required this.contactPhone,
  });

  final String participantName;
  final String participantPhone;
  final String contactName;
  final String contactPhone;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        participantName: json['nome_participante']?.toString() ?? '',
        participantPhone: json['telefone_participante']?.toString() ?? '',
        contactName: json['contato_emergencia_nome']?.toString() ?? '',
        contactPhone: json['contato_emergencia_telefone']?.toString() ?? '',
      );
}
