import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../data/demo_data.dart' as demo;
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/local_booking.dart';
import '../models/local_guide.dart';
import '../models/support_message.dart';
import '../models/trail.dart';
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

  final List<AppNotificationItem> notifications = <AppNotificationItem>[];

  final List<ChatMessage> messages = <ChatMessage>[];
  final List<SupportMessage> supportMessages = <SupportMessage>[];

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

      _loadList<ChatMessage>(
        key: 'messages',
        target: messages,
        decoder: ChatMessage.fromJson,
        fallback: [
          ChatMessage(
            id: 'welcome-chat',
            senderRole: 'guia',
            recipientRole: 'turista',
            guideName: guide.name,
            text:
                'Olá! Se tiver alguma dúvida sobre a trilha, pode falar comigo por aqui.',
            createdAt: DateTime.now(),
          ),
        ],
      );

      _loadList<SupportMessage>(
        key: 'support_messages',
        target: supportMessages,
        decoder: SupportMessage.fromJson,
        fallback: [],
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
      messages.clear();
      supportMessages.clear();
      favoriteTrailIds.clear();
    }

    // A central de notificações pode continuar sendo
    // armazenada localmente mesmo usando backend.
    _loadList<AppNotificationItem>(
      key: 'notifications',
      target: notifications,
      decoder: AppNotificationItem.fromJson,
      fallback: [],
    );

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

  Future<void> updateUser(
    String role, {
    required String name,
    required String email,
    required String phone,
    required String city,
    required String state,
    String? document,
    String? profileImageDataUrl,
    bool updateProfileImage = false,
  }) async {
    _requireLocalBusinessMode('Atualização de perfil');

    final user = userForRole(role);

    user.name = name;
    user.email = email;
    user.phone = phone;
    user.city = city;
    user.state = state;

    if (document != null) {
      user.document = document;
    }

    if (updateProfileImage) {
      user.profileImageDataUrl = profileImageDataUrl;
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
    _requireLocalBusinessMode('Cadastro de trilha');

    trails.insert(0, trail);

    await addNotification(
      title: 'Trilha adicionada',
      body: '${trail.name} foi adicionada ao RotaFácil.',
    );

    await _persistAll();

    notifyListeners();
  }

  Future<void> updateTrail(Trail trail) async {
    _requireLocalBusinessMode('Atualização de trilha');

    final index = trails.indexWhere((item) => item.id == trail.id);

    if (index < 0) {
      return;
    }

    trails[index] = trail;

    await _persistAll();

    notifyListeners();
  }

  Future<void> removeTrail(Trail trail) async {
    _requireLocalBusinessMode('Exclusão de trilha');

    trails.removeWhere((item) => item.id == trail.id);

    favoriteTrailIds.remove(trail.id);

    await _persistAll();

    notifyListeners();
  }

  Future<void> addBooking(LocalBooking booking) async {
    _requireLocalBusinessMode('Criação de agendamento');

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
    _requireLocalBusinessMode('Cancelamento de agendamento');

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

  Future<void> toggleFavorite(String trailId) async {
    _requireLocalBusinessMode('Alteração de favoritos');

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
    item.read = true;

    await _persistAll();

    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    for (final item in notifications) {
      item.read = true;
    }

    await _persistAll();

    notifyListeners();
  }

  int get unreadNotifications {
    return notifications.where((item) => !item.read).length;
  }

  Future<void> sendDirectMessage({
    required String senderRole,
    required String recipientRole,
    required String text,
    String? guideName,
  }) async {
    _requireLocalBusinessMode('Envio de mensagem');

    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return;
    }

    final channelGuide = guideName == null || guideName.trim().isEmpty
        ? guide.name
        : guideName.trim();

    messages.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        senderRole: normalizeRole(senderRole),
        recipientRole: normalizeRole(recipientRole),
        guideName: channelGuide,
        text: trimmed,
        createdAt: DateTime.now(),
      ),
    );

    await _persistAll();

    notifyListeners();
  }

  List<ChatMessage> conversationBetween(
    String roleA,
    String roleB, {
    String? guideName,
  }) {
    final first = normalizeRole(roleA);

    final second = normalizeRole(roleB);

    final channelGuide = guideName == null || guideName.trim().isEmpty
        ? guide.name
        : guideName.trim();

    final result = messages.where((message) {
      final roleMatch =
          (message.senderRole == first && message.recipientRole == second) ||
          (message.senderRole == second && message.recipientRole == first);

      if (!roleMatch) {
        return false;
      }

      if (message.guideName.trim().isEmpty) {
        return channelGuide == guide.name;
      }

      return message.guideName.toLowerCase() == channelGuide.toLowerCase();
    }).toList();

    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return result;
  }

  Future<void> sendSupportMessage({
    required String userRole,
    required String text,
  }) async {
    _requireLocalBusinessMode('Envio de mensagem ao suporte');

    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return;
    }

    final role = normalizeRole(userRole);

    supportMessages.add(
      SupportMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userRole: role,
        sender: 'user',
        text: trimmed,
        createdAt: DateTime.now(),
      ),
    );

    await _persistAll();

    notifyListeners();
  }

  Future<void> replyAsSupport({
    required String userRole,
    required String text,
  }) async {
    _requireLocalBusinessMode('Resposta do suporte');

    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return;
    }

    supportMessages.add(
      SupportMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userRole: normalizeRole(userRole),
        sender: 'support',
        text: trimmed,
        createdAt: DateTime.now(),
      ),
    );

    await addNotification(title: 'Resposta do suporte', body: trimmed);

    await _persistAll();

    notifyListeners();
  }

  List<SupportMessage> supportConversationForRole(String userRole) {
    final role = normalizeRole(userRole);

    final result = supportMessages
        .where((message) => message.userRole == role)
        .toList();

    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return result;
  }

  Future<void> setPushNotifications(bool value) async {
    pushNotifications = value;

    await _persistAll();

    notifyListeners();
  }

  Future<void> setBookingNotifications(bool value) async {
    bookingNotifications = value;

    await _persistAll();

    notifyListeners();
  }

  Future<void> setMarketingNotifications(bool value) async {
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
    await _prefs.setString('user_tourist', jsonEncode(tourist.toJson()));

    await _prefs.setString('user_guide', jsonEncode(guide.toJson()));

    await _prefs.setString('user_agency', jsonEncode(agency.toJson()));

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

      await _prefs.setString(
        'messages',
        jsonEncode(messages.map((item) => item.toJson()).toList()),
      );

      await _prefs.setString(
        'support_messages',
        jsonEncode(supportMessages.map((item) => item.toJson()).toList()),
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
