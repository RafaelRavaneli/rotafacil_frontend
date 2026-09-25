import '../models/app_user.dart';
import '../models/local_guide.dart';
import '../models/local_booking.dart';
import '../models/trail.dart';
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
  ]);
  final List<LocalGuide> guides;
  final AppUser user;
  final List<Trail> trails;
  final Set<String> favorites;
  final List<LocalBooking> bookings;
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
      if (role == 'guia' || role == 'agencia')
        api.get('/api/agendamentos/guia/${Uri.encodeComponent(id)}'),
      if ((role == 'guia' || role == 'agencia') && session.email != null)
        api.get(
          '/api/agendamentos/guia/${Uri.encodeComponent(session.email!)}',
        ),
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
        trailName: trail?.name ?? 'Trilha indisponível',
        personName: row['id_usuario'] == id ? user.name : 'Participante',
        date: row['data_agendada']?.toString() ?? '',
        status: row['status']?.toString() ?? '',
        roleView: role,
        valuePaid: double.tryParse(row['valor_pago']?.toString() ?? '') ?? 0,
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
    return BackendSnapshot(user, trails, favorites, bookings, guides);
  }

  static String apiDate(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})').firstMatch(value);
    if (match != null) return '${match[3]}-${match[2]}-${match[1]}';
    return value;
  }

  Future<String> uploadImage(String image) async {
    if (!image.startsWith('data:')) return image;
    final data = UriData.parse(image);
    final result = await api.uploadMultipart(
      '/api/uploads/imagem',
      bytes: data.contentAsBytes(),
      fileName: 'foto.jpg',
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
      'distancia_km': trail.distanceKm,
      'data_atividade': apiDate(trail.date),
      'imagem_url': await uploadImage(trail.imageUrl),
      'preco': trail.price,
      'ativo': TrailStatus.isActive(trail.status),
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
}
