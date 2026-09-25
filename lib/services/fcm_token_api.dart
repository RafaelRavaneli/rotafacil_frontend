import '../config/app_config.dart';
import 'api_client.dart';
import 'session_service.dart';

class FcmTokenApi {
  FcmTokenApi._();

  static final FcmTokenApi instance = FcmTokenApi._();

  bool get canSync =>
      AppConfig.useBackend &&
      (SessionService.instance.token?.isNotEmpty ?? false);

  Future<void> register(String token) async {
    if (!canSync) return;

    await ApiClient.instance.post(
      AppConfig.fcmTokenPath,
      body: {'token': token},
    );
  }

  Future<void> remove() async {
    if (!canSync) return;

    await ApiClient.instance.delete(AppConfig.fcmTokenPath);
  }
}
