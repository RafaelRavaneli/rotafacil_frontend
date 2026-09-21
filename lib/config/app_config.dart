class AppConfig {
  const AppConfig._();

  static const bool useBackend = bool.fromEnvironment(
    'USE_BACKEND',
    defaultValue: false,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );

  static const String firebaseWebVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
    defaultValue: '',
  );

  static const String fcmTokenPath = '/api/usuarios/fcm-token';

  static const String resetPasswordPath = String.fromEnvironment(
    'RESET_PASSWORD_PATH',
    defaultValue: '',
  );
}
