import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../config/app_config.dart';
import '../config/firebase_runtime_options.dart';
import '../state/app_store.dart';
import 'fcm_token_api.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      if (FirebaseRuntimeOptions.isConfigured) {
        await Firebase.initializeApp(
          options: FirebaseRuntimeOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }
    }
  } catch (_) {
    // Se a configuração do projeto Firebase ainda não existir,
    // o app principal continua funcionando normalmente.
  }
}

class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  bool firebaseReady = false;
  bool initializing = false;
  String? token;
  String permissionLabel = 'Não solicitado';

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  bool get platformSupportsFcm {
    if (kIsWeb) return true;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> initialize() async {
    if (initializing || firebaseReady || !platformSupportsFcm) {
      return;
    }

    initializing = true;
    notifyListeners();

    try {
      if (Firebase.apps.isEmpty) {
        if (FirebaseRuntimeOptions.isConfigured) {
          await Firebase.initializeApp(
            options: FirebaseRuntimeOptions.currentPlatform,
          );
        } else if (kIsWeb) {
          // A configuração web deve ser explícita; não atrasa o login sem ela.
          return;
        } else {
          await Firebase.initializeApp();
        }
      }

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }

      firebaseReady = true;

      _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
        _handleForeground,
      );

      _openedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
        _handleOpened,
      );

      _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen((
        newToken,
      ) async {
        token = newToken;
        notifyListeners();

        try {
          if (AppStore.instance.pushNotifications) {
            await FcmTokenApi.instance.register(newToken);
          }
        } catch (_) {}
      });

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      if (initialMessage != null) {
        await _saveMessage(initialMessage);
      }
    } catch (_) {
      firebaseReady = false;
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<NotificationSettings?> requestPermission() async {
    await initialize();

    if (!firebaseReady) return null;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    permissionLabel = _permissionName(settings.authorizationStatus);

    notifyListeners();
    return settings;
  }

  Future<String?> captureToken() async {
    await initialize();

    if (!firebaseReady) return null;

    final webKey = AppConfig.firebaseWebVapidKey;

    token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb && webKey.isNotEmpty ? webKey : null,
    );

    notifyListeners();
    return token;
  }

  Future<void> registerAfterLogin() async {
    if (!AppStore.instance.pushNotifications) return;

    final settings = await requestPermission();
    if (settings == null) return;

    final allowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!allowed) return;

    final currentToken = await captureToken();
    if (currentToken == null || currentToken.isEmpty) return;

    try {
      await FcmTokenApi.instance.register(currentToken);
    } catch (error) {
      await AppStore.instance.addNotification(
        title: 'Aviso de notificações',
        body:
            'O token FCM foi obtido, mas não foi sincronizado com a API: $error',
      );
    }
  }

  Future<void> unregisterOnLogout() async {
    try {
      await FcmTokenApi.instance.remove();
    } catch (_) {}

    try {
      if (firebaseReady) await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    token = null;
    notifyListeners();
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    await _saveMessage(message);

    final notification = message.notification;
    final title = notification?.title ?? 'Nova notificação do RotaFácil';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        'Você recebeu uma nova atualização.';

    appScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('$title\n$body')),
    );
  }

  Future<void> _handleOpened(RemoteMessage message) async {
    await _saveMessage(message);
  }

  Future<void> _saveMessage(RemoteMessage message) async {
    final notification = message.notification;

    await AppStore.instance.addNotification(
      title: notification?.title ?? 'Notificação do RotaFácil',
      body:
          notification?.body ??
          message.data['body']?.toString() ??
          message.data.toString(),
    );
  }

  String _permissionName(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'Permitida';
      case AuthorizationStatus.denied:
        return 'Negada';
      case AuthorizationStatus.deniedPermanently:
        return 'Negada permanentemente';
      case AuthorizationStatus.notDetermined:
        return 'Não solicitada';
      case AuthorizationStatus.provisional:
        return 'Provisória';
    }
  }
}
