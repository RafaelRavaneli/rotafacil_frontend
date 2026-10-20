import 'dart:typed_data';

import '../models/app_user.dart';
import '../models/local_guide.dart';
import '../models/local_booking.dart';
import '../models/trail.dart';
import '../models/trail_experience.dart';
import '../models/availability.dart';
import '../models/professional_document.dart';
import '../models/app_notification.dart';
import '../models/guide.dart';
import '../utils/role_utils.dart';
import 'api_client.dart';
import 'session_service.dart';

class BackendSnapshot {
  const BackendSnapshot(
    this.user,
    this.trails,
    this.favorites,
    this.bookings, [
    this.guides = const [],
    this.dashboard,
  ]);
  final List<LocalGuide> guides;
  final OperatorDashboardSummary? dashboard;
  final AppUser user;
  final List<Trail> trails;
  final Set<String> favorites;
  final List<LocalBooking> bookings;
}

class OperatorDashboardSummary {
  const OperatorDashboardSummary({
    required this.total,
    required this.byStatus,
    required this.declaredValue,
  });

  final int total;
  final Map<String, int> byStatus;
  final double declaredValue;

  int get active =>
      (byStatus['agendado'] ?? 0) +
      (byStatus['pendente'] ?? 0) +
      (byStatus['confirmado'] ?? 0) +
      (byStatus['em_andamento'] ?? 0);

  factory OperatorDashboardSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['por_status'];
    final byStatus = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        byStatus[entry.key.toString()] =
            int.tryParse(entry.value.toString()) ?? 0;
      }
    }
    return OperatorDashboardSummary(
      total: int.tryParse(json['total_agendamentos']?.toString() ?? '') ?? 0,
      byStatus: byStatus,
      declaredValue:
          double.tryParse(json['valor_declarado_ativo']?.toString() ?? '') ?? 0,
    );
  }
}

class BackendRepository {
  BackendRepository({ApiClient? api}) : api = api ?? ApiClient.instance;
  final ApiClient api;

  static List<Map<String, dynamic>> records(dynamic data) {
    if (data is! List) throw const FormatException('Resposta inválida da API.');
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<BackendSnapshot> load() async {
    final session = SessionService.instance;
    final id = session.userId;
    if (id == null || id.isEmpty) {
      throw ApiException('Faça login novamente para carregar sua conta.', 401);
    }
    final role = normalizeRoleKey(session.role ?? '');
    final result = await Future.wait([
      api.get('/api/usuarios/${Uri.encodeComponent(id)}'),
      api.get('/api/trilhas/'),
      api.get('/api/favoritos/'),
      api.get('/api/agendamentos/usuario/${Uri.encodeComponent(id)}'),
      if (role == 'guia')
        api.get('/api/agendamentos/guia/${Uri.encodeComponent(id)}'),
      if (role == 'agencia')
        api.get('/api/agendamentos/agencia/${Uri.encodeComponent(id)}'),
    ]);
    final user = AppUser.fromJson(Map<String, dynamic>.from(result[0] as Map));
    final trails = records(result[1]).map(Trail.fromJson).toList();
    final favorites = records(
      result[2],
    ).map((row) => row['id'].toString()).toSet();
    final bookingRows = <String, Map<String, dynamic>>{};
    for (final response in result.skip(3)) {
      for (final row in records(response)) {
        bookingRows[row['id'].toString()] = row;
      }
    }
    final byId = {for (final trail in trails) trail.id: trail};
    final bookings = bookingRows.values.map((row) {
      final trail = byId[row['id_trilha']];
      return LocalBooking(
        id: row['id'].toString(),
        trailId: row['id_trilha'].toString(),
        trailName: trail?.name ?? 'Roteiro indisponível',
        personName:
            row['nome_usuario']?.toString() ??
            (row['id_usuario'] == id ? user.name : 'Participante'),
        date: row['data_agendada']?.toString() ?? '',
        status: row['status']?.toString() ?? '',
        roleView: role,
        valuePaid: double.tryParse(row['valor_pago']?.toString() ?? '') ?? 0,
        personId: row['id_usuario']?.toString() ?? '',
        guideId: row['id_guia']?.toString() ?? '',
      );
    }).toList();
    final guides = <LocalGuide>[];
    if (role == 'agencia') {
      final invites = records(await api.get('/api/convites-guias'));
      for (final invite in invites.where(
        (item) => item['status'] == 'aceito',
      )) {
        guides.add(
          LocalGuide(
            id: invite['id_guia'].toString(),
            name: invite['nome_guia']?.toString() ?? 'Guia',
            email: '',
            specialty: '',
            status: 'Ativo',
          ),
        );
      }
    }
    final dashboard = role == 'guia' || role == 'agencia'
        ? await dashboardSummary(id)
        : null;
    return BackendSnapshot(
      user,
      trails,
      favorites,
      bookings,
      guides,
      dashboard,
    );
  }

  Future<OperatorDashboardSummary> dashboardSummary(String operatorId) async {
    final result = await api.get(
      '/api/agendamentos/dashboard/${Uri.encodeComponent(operatorId)}',
    );
    if (result is! Map) {
      throw const FormatException('Resumo do painel inválido.');
    }
    return OperatorDashboardSummary.fromJson(Map<String, dynamic>.from(result));
  }

  static String apiDate(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})').firstMatch(value);
    if (match != null) return '${match[3]}-${match[2]}-${match[1]}';
    return value;
  }

  Future<String> uploadImage(String image) async {
    if (!image.startsWith('data:')) return image;
    final data = UriData.parse(image);
    final extension = switch (data.mimeType.toLowerCase()) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final result = await api.uploadMultipart(
      '/api/uploads/imagem',
      bytes: data.contentAsBytes(),
      fileName: 'foto.$extension',
      fieldName: 'image',
    );
    final url = result is Map ? result['url']?.toString() : null;
    if (url == null || url.isEmpty) {
      throw const FormatException('A API não retornou a URL da imagem.');
    }
    return url;
  }

  Future<void> saveTrail(Trail trail, {required bool create}) async {
    final body = <String, dynamic>{
      'nome': trail.name,
      'descricao': trail.description,
      'cidade': trail.city,
      'estado': trail.state,
      'dificuldade': trail.difficulty,
      'modalidade': trail.modality,
      'atividades': trail.effectiveActivities,
      'distancia_km': trail.distanceKm,
      'data_atividade': apiDate(trail.date),
      'data_fim': apiDate(trail.endDate.isEmpty ? trail.date : trail.endDate),
      'data_hora_inicio': trail.startDateTime,
      'data_hora_fim': trail.endDateTime,
      'datas': trail.effectiveDepartures.map((item) => item.toJson()).toList(),
      'imagem_url': await uploadImage(trail.imageUrl),
      'preco': trail.price,
      'ativo': TrailStatus.isActive(trail.status),
      'arquivado': trail.archived,
      'acessivel': trail.accessible,
      'itens_recomendados': trail.recommendedItems,
      'trajeto': trail.route.map((point) => point.toJson()).toList(),
      if (trail.meetingPoint.trim().isNotEmpty)
        'ponto_encontro': trail.meetingPoint.trim(),
      'capacidade': trail.capacity,
      'horario_inicio': trail.startTime,
      'horario_fim': trail.endTime,
      if (trail.guideId.isNotEmpty) 'id_guia': trail.guideId,
      if (trail.latitude != null && trail.longitude != null) ...{
        'latitude': trail.latitude,
        'longitude': trail.longitude,
      },
    };
    if (create) {
      await api.post('/api/trilhas/', body: body);
    } else {
      await api.put(
        '/api/trilhas/${Uri.encodeComponent(trail.id)}',
        body: body,
      );
    }
  }

  Future<List<TrailReview>> reviews(String trailId) async {
    final response = await api.get(
      '/api/avaliacoes/trilha/${Uri.encodeComponent(trailId)}',
    );
    return records(response).map(TrailReview.fromJson).toList();
  }

  Future<GuideProfile> publicGuide(String guideId) async {
    final result = await api.get('/api/guias/${Uri.encodeComponent(guideId)}');
    if (result is! Map) {
      throw const FormatException('Resposta inválida da API.');
    }
    return GuideProfile.fromJson(Map<String, dynamic>.from(result));
  }

  Future<void> addReview({
    required String trailId,
    required int rating,
    required String comment,
  }) async {
    await api.post(
      '/api/avaliacoes/',
      body: {'id_trilha': trailId, 'nota': rating, 'comentario': comment},
    );
  }

  Future<TrailWeather?> weather(String trailId) async {
    final response = Map<String, dynamic>.from(
      await api.get('/api/trilhas/${Uri.encodeComponent(trailId)}/clima')
          as Map,
    );
    final current = response['previsao_do_dia_da_trilha'];
    if (current is! Map) return null;
    return TrailWeather.fromJson(Map<String, dynamic>.from(current));
  }

  Future<EmergencyContact> emergencyContact(String userId) async {
    final response = await api.get(
      '/api/usuarios/${Uri.encodeComponent(userId)}/contato-emergencia',
    );
    return EmergencyContact.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> checkIn(
    String bookingId, {
    double? latitude,
    double? longitude,
  }) async {
    await api.put(
      '/api/agendamentos/${Uri.encodeComponent(bookingId)}/checkin',
      body: {'latitude': ?latitude, 'longitude': ?longitude},
    );
  }

  Future<void> checkOut(String bookingId) async {
    await api.put(
      '/api/agendamentos/${Uri.encodeComponent(bookingId)}/checkout',
    );
  }

  Future<List<Availability>> availabilities({String? guideId}) async {
    final response = await api.get(
      '/api/disponibilidades/',
      queryParameters: {'guia_id': ?guideId},
    );
    return records(response).map(Availability.fromJson).toList();
  }

  Future<void> createAvailability({
    required String date,
    required String startTime,
    required String endTime,
    required String type,
    required String note,
    int? capacity,
  }) async {
    await api.post(
      '/api/disponibilidades/',
      body: {
        'data': date,
        'horario_inicio': startTime,
        'horario_fim': endTime,
        'tipo': type,
        'observacao': note,
        'capacidade': ?capacity,
      },
    );
  }

  Future<void> deleteAvailability(String id) async {
    await api.delete('/api/disponibilidades/${Uri.encodeComponent(id)}');
  }

  Future<void> deleteAccount(String userId) async {
    await api.delete('/api/usuarios/${Uri.encodeComponent(userId)}');
  }

  Future<void> changeAccountType({
    required String userId,
    required String type,
    String? document,
  }) async {
    await api.put(
      '/api/usuarios/${Uri.encodeComponent(userId)}/tipo',
      body: {'tipo': type, 'documento': ?document},
    );
  }

  Future<List<ProfessionalDocument>> professionalDocuments({
    String? status,
  }) async {
    final response = await api.get(
      '/api/documentos-profissionais/',
      queryParameters: {'status': ?status},
    );
    return records(response).map(ProfessionalDocument.fromJson).toList();
  }

  Future<void> uploadProfessionalDocument({
    required List<int> bytes,
    required String fileName,
    required String documentType,
  }) async {
    await api.uploadMultipart(
      '/api/documentos-profissionais/',
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
      fieldName: 'arquivo',
      fields: {'tipo_documento': documentType},
    );
  }

  Future<Uint8List> professionalDocumentBytes(String id) {
    return api.getBytes(
      '/api/documentos-profissionais/${Uri.encodeComponent(id)}/arquivo',
    );
  }

  Future<void> deleteProfessionalDocument(String id) async {
    await api.delete(
      '/api/documentos-profissionais/${Uri.encodeComponent(id)}',
    );
  }

  Future<void> reviewProfessionalDocument({
    required String id,
    required String status,
    String note = '',
  }) async {
    await api.put(
      '/api/documentos-profissionais/${Uri.encodeComponent(id)}/analise',
      body: {'status': status, 'observacao': note},
    );
  }

  Future<List<AppNotificationItem>> notifications() async {
    final response = await api.get('/api/notificacoes/');
    return records(response).map(AppNotificationItem.fromJson).toList();
  }

  Future<Map<String, bool>> notificationPreferences() async {
    final response = Map<String, dynamic>.from(
      await api.get('/api/notificacoes/preferencias') as Map,
    );
    return {
      'push': response['push'] != false,
      'agendamentos': response['agendamentos'] != false,
      'marketing': response['marketing'] == true,
    };
  }

  Future<void> markNotificationRead(String id) async {
    await api.put('/api/notificacoes/${Uri.encodeComponent(id)}/lida');
  }

  Future<void> markAllNotificationsRead() async {
    await api.put('/api/notificacoes/lidas');
  }

  Future<void> updateNotificationPreferences(Map<String, bool> values) async {
    await api.put('/api/notificacoes/preferencias', body: values);
  }
}
