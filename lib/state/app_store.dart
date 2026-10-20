import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/backend_repository.dart';
import '../services/local_auth_service.dart';
import '../services/session_service.dart';
import '../data/demo_data.dart' as demo;
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/local_booking.dart';
import '../models/local_guide.dart';
import '../models/trail.dart';
import '../models/trail_experience.dart';
import '../models/professional_document.dart';
import '../models/guide.dart';
import '../utils/role_utils.dart';

class AppStore extends ChangeNotifier {
  AppStore._();

  static final AppStore instance = AppStore._();

  late SharedPreferences _prefs;

  bool _initialized = false;

  AppUser tourist = AppUser(
    name: 'Thiago',
    email: 'thiago@email.com',
    phone: '(44) 99999-0000',
    city: 'Maringá',
    state: 'PR',
    role: 'Turista',
  );

  AppUser guide = AppUser(
    name: 'Rafael Souza',
    email: 'guia@email.com',
    phone: '(44) 99999-1111',
    city: 'Maringá',
    state: 'PR',
    role: 'Guia',
    document: '52998224725',
  );

  AppUser agency = AppUser(
    name: 'Aventura Prime',
    email: 'contato@aventuraprime.com',
    phone: '(44) 3333-4444',
    city: 'Maringá',
    state: 'PR',
    role: 'Agência',
    document: '11222333000181',
  );

  final List<Trail> trails = <Trail>[];
  final List<LocalGuide> agencyGuides = <LocalGuide>[];
  final List<LocalBooking> bookings = <LocalBooking>[];
  OperatorDashboardSummary? operatorDashboardSummary;

  final List<AppNotificationItem> notifications = <AppNotificationItem>[];

  final Set<String> favoriteTrailIds = <String>{};

  bool pushNotifications = true;
  bool bookingNotifications = true;
  bool marketingNotifications = false;
  bool biometricLock = false;
  bool profileVisible = true;

  bool get initialized => _initialized;

  /// Indica qual modo o aplicativo está usando.
  bool get useBackend => AppConfig.useBackend;

  /// Impede que uma operação que deveria ir para a API
  /// seja salva somente no dispositivo quando o backend
  /// estiver ativado.
  void _requireLocalBusinessMode(String operation) {
    if (!AppConfig.useBackend) {
      return;
    }

    throw StateError(
      '$operation ainda não possui endpoint de backend configurado.',
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Perfil continua disponível localmente como cache/interface.
    tourist = _loadUser('user_tourist', tourist);

    guide = _loadUser('user_guide', guide);

    agency = _loadUser('user_agency', agency);

    if (guide.document.isEmpty) {
      guide.document = '52998224725';
    }

    if (agency.document.isEmpty) {
      agency.document = '11222333000181';
    }

    if (!AppConfig.useBackend) {
      // MODO LOCAL:
      // carrega os dados demonstrativos e persistidos
      // no dispositivo.

      _loadList<Trail>(
        key: 'trails',
        target: trails,
        decoder: Trail.fromJson,
        fallback: List<Trail>.from(demo.trails),
      );

      _loadList<LocalGuide>(
        key: 'agency_guides',
        target: agencyGuides,
        decoder: LocalGuide.fromJson,
        fallback: [
          LocalGuide(
            id: 'g1',
            name: 'Lucas Andrade',
            email: 'lucas@guia.com',
            specialty: 'Montanhismo',
            status: 'Ativo',
          ),
          LocalGuide(
            id: 'g2',
            name: 'Fernanda Melo',
            email: 'fernanda@guia.com',
            specialty: 'Ecoturismo',
            status: 'Ativo',
          ),
        ],
      );

      _loadList<LocalBooking>(
        key: 'bookings',
        target: bookings,
        decoder: LocalBooking.fromJson,
        fallback: [
          LocalBooking(
            id: 'b1',
            trailId: 'cachoeira',
            trailName: 'Trilha da Cachoeira do Véu',
            personName: 'João Silva',
            date: '20/05/2026 • 08:00',
            status: 'Confirmado',
            roleView: 'guia',
            valuePaid: 189,
          ),
          LocalBooking(
            id: 'b2',
            trailId: 'mirante',
            trailName: 'Trilha do Mirante',
            personName: 'Mariana Costa',
            date: '21/05/2026 • 07:30',
            status: 'Pendente',
            roleView: 'agencia',
            valuePaid: 129,
          ),
          LocalBooking(
            id: 'b3',
            trailId: 'marumbi',
            trailName: 'Pico do Marumbi',
            personName: 'Thiago',
            date: '30/09/2026 • 07:00',
            status: 'Confirmado',
            roleView: 'turista',
            valuePaid: 219,
          ),
        ],
      );

      favoriteTrailIds
        ..clear()
        ..addAll(_prefs.getStringList('favorites') ?? []);
    } else {
      // MODO BACKEND:
      // Não usa dados de negócio locais como se fossem
      // dados vindos do servidor.
      //
      // Quando as rotas oficiais existirem,
      // este ponto poderá carregar tudo pela API.

      trails.clear();
      agencyGuides.clear();
      bookings.clear();
      operatorDashboardSummary = null;
      favoriteTrailIds.clear();
    }

    if (useBackend) {
      notifications.clear();
    } else {
      _loadList<AppNotificationItem>(
        key: 'notifications',
        target: notifications,
        decoder: AppNotificationItem.fromJson,
        fallback: [],
      );
    }

    // Preferências do aparelho continuam locais.
    pushNotifications = _prefs.getBool('pushNotifications') ?? true;

    bookingNotifications = _prefs.getBool('bookingNotifications') ?? true;

    marketingNotifications = _prefs.getBool('marketingNotifications') ?? false;

    biometricLock = _prefs.getBool('biometricLock') ?? false;

    profileVisible = _prefs.getBool('profileVisible') ?? true;

    _initialized = true;

    await _persistAll();

    notifyListeners();
  }

  AppUser _loadUser(String key, AppUser fallback) {
    final raw = _prefs.getString(key);

    if (raw == null || raw.isEmpty) {
      return fallback;
    }

    try {
      return AppUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return fallback;
    }
  }

  void _loadList<T>({
    required String key,
    required List<T> target,
    required T Function(Map<String, dynamic>) decoder,
    required List<T> fallback,
  }) {
    target.clear();

    final raw = _prefs.getString(key);

    if (raw == null || raw.isEmpty) {
      target.addAll(fallback);
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      target.addAll(
        decoded.map((item) => decoder(Map<String, dynamic>.from(item as Map))),
      );
    } catch (_) {
      target.addAll(fallback);
    }
  }

  String normalizeRole(String role) => normalizeRoleKey(role);

  AppUser userForRole(String role) {
    switch (normalizeRole(role)) {
      case 'guia':
        return guide;

      case 'agencia':
        return agency;

      default:
        return tourist;
    }
  }

  List<Trail> get managedTrails {
    if (!useBackend) return trails;
    final session = SessionService.instance;
    final owners = {session.userId, session.email}
      ..removeWhere((id) => id == null || id.isEmpty);
    return trails
        .where(
          (trail) =>
              owners.contains(trail.createdBy) ||
              (trail.createdBy.trim().isEmpty &&
                  owners.contains(trail.guideId)),
        )
        .toList();
  }

  void syncAgencyGuides(List<Map<String, dynamic>> invitations) {
    agencyGuides
      ..clear()
      ..addAll(
        invitations
            .where((item) => item['status'] == 'aceito')
            .map(
              (item) => LocalGuide(
                id: item['id_guia'].toString(),
                name: item['nome_guia']?.toString() ?? 'Guia',
                email: '',
                specialty: '',
                status: 'Ativo',
              ),
            ),
      );
    notifyListeners();
  }

  final _backend = BackendRepository();
  Future<void>? _refreshBackendInFlight;

  Future<void> refreshBackend() async {
    if (!useBackend) return;
    final activeRefresh = _refreshBackendInFlight;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _loadBackend();
    _refreshBackendInFlight = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_refreshBackendInFlight, refresh)) {
        _refreshBackendInFlight = null;
      }
    }
  }

  Future<void> _loadBackend() async {
    final snapshot = await _backend.load();
    agencyGuides
      ..clear()
      ..addAll(snapshot.guides);
    switch (normalizeRole(snapshot.user.role)) {
      case 'guia':
        guide = snapshot.user;
        break;
      case 'agencia':
        agency = snapshot.user;
        break;
      default:
        tourist = snapshot.user;
    }
    trails
      ..clear()
      ..addAll(snapshot.trails);
    bookings
      ..clear()
      ..addAll(snapshot.bookings);
    operatorDashboardSummary = snapshot.dashboard;
    favoriteTrailIds
      ..clear()
      ..addAll(snapshot.favorites);
    await refreshNotifications();
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    if (!useBackend) return;
    final results = await Future.wait([
      _backend.notifications(),
      _backend.notificationPreferences(),
    ]);
    notifications
      ..clear()
      ..addAll(results[0] as List<AppNotificationItem>);
    final preferences = results[1] as Map<String, bool>;
    pushNotifications = preferences['push'] ?? true;
    bookingNotifications = preferences['agendamentos'] ?? true;
    marketingNotifications = preferences['marketing'] ?? false;
    notifyListeners();
  }

  Future<void> updateUser(
    String role, {
    required String name,
    required String email,
    required String phone,
    required String city,
    required String state,
    String? document,
    String? cadasturNumber,
    String? cadasturValidUntil,
    String? profileImageDataUrl,
    bool updateProfileImage = false,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? professionalDescription,
    List<String>? specialties,
  }) async {
    if (useBackend) {
      final session = SessionService.instance;
      final body = <String, dynamic>{
        'nome': name,
        'email': email,
        'telefone': phone,
        'cidade': city,
        'estado': state,
        if (document != null && document.isNotEmpty) 'documento': document,
        'cadastur_numero': ?cadasturNumber,
        'cadastur_validade': ?cadasturValidUntil,
        if (updateProfileImage)
          'foto_url': profileImageDataUrl == null
              ? null
              : await _backend.uploadImage(profileImageDataUrl),
        'contato_emergencia_nome': ?emergencyContactName,
        'contato_emergencia_telefone': ?emergencyContactPhone,
        'descricao_profissional': ?professionalDescription,
        'especialidades': ?specialties,
      };
      await ApiClient.instance.put(
        '/api/usuarios/${Uri.encodeComponent(session.userId!)}',
        body: body,
      );
      await session.save(
        authToken: session.token,
        selectedRole: session.role!,
        userEmail: email,
        id: session.userId,
      );
      await refreshBackend();
      return;
    }

    final user = userForRole(role);

    user.name = name;
    user.email = email;
    user.phone = phone;
    user.city = city;
    user.state = state;

    if (document != null) {
      user.document = document;
    }
    if (cadasturNumber != null) user.cadasturNumber = cadasturNumber;
    if (cadasturValidUntil != null) {
      user.cadasturValidUntil = cadasturValidUntil;
    }

    if (updateProfileImage) {
      user.profileImageDataUrl = profileImageDataUrl;
    }
    if (emergencyContactName != null) {
      user.emergencyContactName = emergencyContactName;
    }
    if (emergencyContactPhone != null) {
      user.emergencyContactPhone = emergencyContactPhone;
    }
    if (professionalDescription != null) {
      user.professionalDescription = professionalDescription;
    }
    if (specialties != null) {
      user.specialties = List.of(specialties);
    }

    await _persistAll();

    notifyListeners();
  }

  Future<void> addGuide({
    required String name,
    required String email,
    required String specialty,
  }) async {
    _requireLocalBusinessMode('Cadastro de guia');

    agencyGuides.add(
      LocalGuide(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        email: email,
        specialty: specialty,
        status: 'Convidado',
      ),
    );

    await addNotification(
      title: 'Novo convite de guia',
      body: 'Convite criado para $name ($email).',
    );

    await _persistAll();

    notifyListeners();
  }

  Future<void> updateGuideStatus(LocalGuide guide, String status) async {
    _requireLocalBusinessMode('Atualização de guia');

    guide.status = status;

    await _persistAll();

    notifyListeners();
  }

  Future<void> removeGuide(LocalGuide guide) async {
    _requireLocalBusinessMode('Remoção de guia');

    agencyGuides.remove(guide);

    await _persistAll();

    notifyListeners();
  }

  Future<void> addTrail(Trail trail) async {
    if (useBackend) {
      await _backend.saveTrail(trail, create: true);
      await refreshBackend();
      return;
    }

    trails.insert(0, trail);

    await addNotification(
      title: 'Roteiro adicionado',
      body: '${trail.name} foi adicionada ao RotaFácil.',
    );

    await _persistAll();

    notifyListeners();
  }

  Future<void> updateTrail(Trail trail) async {
    if (useBackend) {
      await _backend.saveTrail(trail, create: false);
      await refreshBackend();
      return;
    }

    final index = trails.indexWhere((item) => item.id == trail.id);

    if (index < 0) {
      return;
    }

    trails[index] = trail;

    await _persistAll();

    notifyListeners();
  }

  Future<void> removeTrail(Trail trail) async {
    if (useBackend) {
      await ApiClient.instance.delete(
        '/api/trilhas/${Uri.encodeComponent(trail.id)}',
      );
      await refreshBackend();
      return;
    }

    if (bookings.any(
      (booking) =>
          booking.trailId == trail.id && BookingStatus.isActive(booking.status),
    )) {
      throw StateError(
        'Este roteiro possui reservas ativas. Cancele ou conclua essas reservas antes de desativá-lo.',
      );
    }

    trails.removeWhere((item) => item.id == trail.id);

    favoriteTrailIds.remove(trail.id);

    await _persistAll();

    notifyListeners();
  }

  Future<void> activateTrail(Trail trail) async {
    if (!useBackend) {
      throw StateError('A reativação está disponível no modo conectado.');
    }
    await ApiClient.instance.put(
      '/api/trilhas/${Uri.encodeComponent(trail.id)}',
      body: const {'ativo': true},
    );
    await refreshBackend();
  }

  Future<void> archiveTrail(Trail trail, {required bool archived}) async {
    if (!useBackend) {
      throw StateError('O arquivamento está disponível no modo conectado.');
    }
    if (archived && !TrailStatus.isInactive(trail.status)) {
      throw StateError('Desative o roteiro antes de arquivá-lo.');
    }
    await ApiClient.instance.put(
      '/api/trilhas/${Uri.encodeComponent(trail.id)}',
      body: {'arquivado': archived},
    );
    await refreshBackend();
  }

  Future<void> addBooking(LocalBooking booking) async {
    if (useBackend) {
      final response = await ApiClient.instance.post(
        '/api/agendamentos/',
        body: {
          'id_trilha': booking.trailId,
          'data_agendada': BackendRepository.apiDate(booking.date),
          if (booking.departureId.isNotEmpty) 'id_data': booking.departureId,
          'valor_pago': booking.valuePaid,
        },
      );
      await refreshBackend();
      final createdId = response is Map ? response['id']?.toString() : null;
      if (createdId != null && createdId.isNotEmpty) {
        final created = bookings
            .where((item) => item.id == createdId)
            .firstOrNull;
        if (created == null || !BookingStatus.isActive(created.status)) {
          throw StateError(
            'A reserva foi criada, mas não voltou como ativa. Atualize a tela antes de tentar novamente.',
          );
        }
      }
      return;
    }

    bookings.insert(0, booking);

    if (bookingNotifications) {
      await addNotification(
        title: 'Agendamento confirmado',
        body: '${booking.trailName} • ${booking.date}',
      );
    }

    await _persistAll();

    notifyListeners();
  }

  Future<void> cancelBooking(LocalBooking booking) async {
    if (!BookingStatus.canCancel(booking.status)) {
      throw StateError(
        'Somente reservas ainda não iniciadas podem ser canceladas.',
      );
    }
    if (useBackend) {
      await ApiClient.instance.put(
        '/api/agendamentos/${Uri.encodeComponent(booking.id)}/cancelar',
      );
      await refreshBackend();
      return;
    }

    booking.status = BookingStatus.cancelled;

    if (bookingNotifications) {
      await addNotification(
        title: 'Agendamento cancelado',
        body: booking.trailName,
      );
    }

    await _persistAll();

    notifyListeners();
  }

  Future<void> checkInBooking(
    LocalBooking booking, {
    double? latitude,
    double? longitude,
  }) async {
    if (!AppConfig.enableCheckInCheckout) {
      throw StateError(
        'Check-in e check-out estão temporariamente indisponíveis.',
      );
    }
    if (useBackend) {
      await _backend.checkIn(
        booking.id,
        latitude: latitude,
        longitude: longitude,
      );
      await refreshBackend();
      return;
    }
    if (!BookingStatus.isConfirmed(booking.status)) {
      throw StateError('Somente reservas confirmadas permitem check-in.');
    }
    booking.status = 'Em andamento';
    await _persistAll();
    notifyListeners();
  }

  Future<void> checkOutBooking(LocalBooking booking) async {
    if (!AppConfig.enableCheckInCheckout) {
      throw StateError(
        'Check-in e check-out estão temporariamente indisponíveis.',
      );
    }
    if (useBackend) {
      await _backend.checkOut(booking.id);
      await refreshBackend();
      return;
    }
    if (BookingStatus.normalize(booking.status) != 'Em andamento') {
      throw StateError('Faça check-in antes de concluir a atividade.');
    }
    booking.status = 'Concluído';
    await _persistAll();
    notifyListeners();
  }

  Future<List<TrailReview>> reviewsFor(String trailId) async {
    if (!useBackend) return const [];
    return _backend.reviews(trailId);
  }

  Future<GuideProfile> publicGuide(String guideId) {
    if (!useBackend) {
      throw StateError('Perfil público remoto exige conexão com o servidor.');
    }
    return _backend.publicGuide(guideId);
  }

  Future<void> reviewTrail({
    required String bookingId,
    required String trailId,
    required int trailRating,
    required int guideRating,
    int? agencyRating,
    required String comment,
  }) async {
    if (!useBackend) {
      throw StateError('Avaliações exigem conexão com o servidor.');
    }
    await _backend.addReview(
      bookingId: bookingId,
      trailId: trailId,
      trailRating: trailRating,
      guideRating: guideRating,
      agencyRating: agencyRating,
      comment: comment,
    );
    await refreshBackend();
  }

  Future<void> respondBooking(LocalBooking booking, String status) async {
    if (!useBackend) {
      booking.status = status;
      notifyListeners();
      return;
    }
    await _backend.respondBooking(booking.id, status);
    await refreshBackend();
  }

  Future<void> finishDeparture({
    required Trail trail,
    required TrailDeparture departure,
  }) async {
    if (!useBackend) {
      for (final booking in bookings.where(
        (item) =>
            item.trailId == trail.id &&
            item.departureId == departure.id &&
            BookingStatus.isConfirmed(item.status),
      )) {
        booking.status = 'Concluído';
      }
      notifyListeners();
      return;
    }
    await _backend.finishDeparture(
      trailId: trail.id,
      departureId: departure.id.startsWith('legacy-') ? '' : departure.id,
      date: departure.startsAt.toIso8601String(),
    );
    await refreshBackend();
  }

  Future<TrailWeather?> weatherFor(String trailId, {DateTime? date}) async {
    if (!useBackend) return null;
    return _backend.weather(trailId, date: date);
  }

  Future<EmergencyContact> emergencyContactFor(String userId) {
    if (!useBackend) {
      throw StateError('Contato de emergência exige conexão com o servidor.');
    }
    return _backend.emergencyContact(userId);
  }

  Future<void> deleteCurrentAccount(String role) async {
    if (useBackend) {
      final userId = SessionService.instance.userId;
      if (userId == null || userId.isEmpty) {
        throw StateError('Faça login novamente para excluir sua conta.');
      }
      await _backend.deleteAccount(userId);
    } else {
      final roleKey = normalizeRole(role);
      await LocalAuthService.instance.deleteAccount(role: roleKey);
      await _prefs.remove('user_$roleKey');
      final empty = AppUser(
        name: '',
        email: '',
        phone: '',
        city: '',
        state: '',
        role: role,
      );
      switch (roleKey) {
        case 'guia':
          guide = empty;
        case 'agencia':
          agency = empty;
        default:
          tourist = empty;
      }
    }

    notifications.clear();
    favoriteTrailIds.clear();
    operatorDashboardSummary = null;
    await _prefs.remove('notifications');
    notifyListeners();
  }

  Future<void> changeAccountType({
    required String type,
    String? document,
    String? cadasturNumber,
    String? cadasturValidUntil,
  }) async {
    if (!useBackend) {
      throw StateError(
        'A alteração do tipo da conta exige conexão com o servidor.',
      );
    }
    final userId = SessionService.instance.userId;
    if (userId == null || userId.isEmpty) {
      throw StateError('Faça login novamente para alterar sua conta.');
    }
    await _backend.changeAccountType(
      userId: userId,
      type: type,
      document: document,
      cadasturNumber: cadasturNumber,
      cadasturValidUntil: cadasturValidUntil,
    );
  }

  Future<List<ProfessionalDocument>> professionalDocuments({String? status}) {
    if (!useBackend) return Future.value(const []);
    return _backend.professionalDocuments(status: status);
  }

  Future<void> uploadProfessionalDocument({
    required List<int> bytes,
    required String fileName,
    required String documentType,
  }) {
    if (!useBackend) {
      throw StateError(
        'Documentos profissionais exigem conexão com o servidor.',
      );
    }
    return _backend.uploadProfessionalDocument(
      bytes: bytes,
      fileName: fileName,
      documentType: documentType,
    );
  }

  Future<Uint8List> professionalDocumentBytes(String id) {
    if (!useBackend) {
      throw StateError(
        'Documentos profissionais exigem conexão com o servidor.',
      );
    }
    return _backend.professionalDocumentBytes(id);
  }

  Future<void> deleteProfessionalDocument(String id) {
    if (!useBackend) {
      throw StateError(
        'Documentos profissionais exigem conexão com o servidor.',
      );
    }
    return _backend.deleteProfessionalDocument(id);
  }

  Future<void> reviewProfessionalDocument({
    required String id,
    required String status,
    String note = '',
  }) {
    if (!useBackend) {
      throw StateError('Análise de documentos exige conexão com o servidor.');
    }
    return _backend.reviewProfessionalDocument(
      id: id,
      status: status,
      note: note,
    );
  }

  Future<void> toggleFavorite(String trailId) async {
    if (useBackend) {
      if (favoriteTrailIds.contains(trailId)) {
        await ApiClient.instance.delete(
          '/api/favoritos/${Uri.encodeComponent(trailId)}',
        );
      } else {
        await ApiClient.instance.post(
          '/api/favoritos/',
          body: {'id_trilha': trailId},
        );
      }
    }

    if (favoriteTrailIds.contains(trailId)) {
      favoriteTrailIds.remove(trailId);
    } else {
      favoriteTrailIds.add(trailId);
    }

    await _persistAll();

    notifyListeners();
  }

  bool isFavorite(String trailId) {
    return favoriteTrailIds.contains(trailId);
  }

  List<Trail> get favoriteTrails {
    return trails.where((trail) => isFavorite(trail.id)).toList();
  }

  Future<void> addNotification({
    required String title,
    required String body,
  }) async {
    notifications.insert(
      0,
      AppNotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );

    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }

    await _persistAll();

    notifyListeners();
  }

  Future<void> markNotificationRead(AppNotificationItem item) async {
    if (useBackend) await _backend.markNotificationRead(item.id);
    item.read = true;

    await _persistAll();

    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    if (useBackend) await _backend.markAllNotificationsRead();
    for (final item in notifications) {
      item.read = true;
    }

    await _persistAll();

    notifyListeners();
  }

  int get unreadNotifications {
    return notifications.where((item) => !item.read).length;
  }

  Future<void> setPushNotifications(bool value) async {
    if (useBackend) {
      await _backend.updateNotificationPreferences({'push': value});
    }
    pushNotifications = value;

    await _persistAll();

    notifyListeners();
  }

  Future<void> setBookingNotifications(bool value) async {
    if (useBackend) {
      await _backend.updateNotificationPreferences({'agendamentos': value});
    }
    bookingNotifications = value;

    await _persistAll();

    notifyListeners();
  }

  Future<void> setMarketingNotifications(bool value) async {
    if (useBackend) {
      await _backend.updateNotificationPreferences({'marketing': value});
    }
    marketingNotifications = value;

    await _persistAll();

    notifyListeners();
  }

  Future<void> setBiometricLock(bool value) async {
    biometricLock = value;

    await _persistAll();

    notifyListeners();
  }

  Future<void> setProfileVisible(bool value) async {
    profileVisible = value;

    await _persistAll();

    notifyListeners();
  }

  Future<void> _persistAll() async {
    // Perfis/cache local.
    if (!useBackend) {
      await _prefs.setString('user_tourist', jsonEncode(tourist.toJson()));
    }

    if (!useBackend) {
      await _prefs.setString('user_guide', jsonEncode(guide.toJson()));
    }

    if (!useBackend) {
      await _prefs.setString('user_agency', jsonEncode(agency.toJson()));
    }

    // Dados de negócio só são persistidos no
    // SharedPreferences quando o aplicativo está
    // realmente no modo local.
    if (!AppConfig.useBackend) {
      await _prefs.setString(
        'trails',
        jsonEncode(trails.map((item) => item.toJson()).toList()),
      );

      await _prefs.setString(
        'agency_guides',
        jsonEncode(agencyGuides.map((item) => item.toJson()).toList()),
      );

      await _prefs.setString(
        'bookings',
        jsonEncode(bookings.map((item) => item.toJson()).toList()),
      );

      await _prefs.setStringList('favorites', favoriteTrailIds.toList());
    }

    // Central de notificações continua local.
    await _prefs.setString(
      'notifications',
      jsonEncode(notifications.map((item) => item.toJson()).toList()),
    );

    // Configurações do dispositivo continuam locais.
    await _prefs.setBool('pushNotifications', pushNotifications);

    await _prefs.setBool('bookingNotifications', bookingNotifications);

    await _prefs.setBool('marketingNotifications', marketingNotifications);

    await _prefs.setBool('biometricLock', biometricLock);

    await _prefs.setBool('profileVisible', profileVisible);
  }
}
