import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'session_service.dart';

class FcmTokenApi {
  FcmTokenApi({ApiClient? api}) : api = api ?? ApiClient.instance;
  static final FcmTokenApi instance = FcmTokenApi();
  final ApiClient api;
  Future<String>? _device;
  bool get canSync =>
      AppConfig.useBackend &&
      (SessionService.instance.token?.isNotEmpty ?? false);
  Future<String> deviceId() => _device ??= _loadDevice();
  Future<String> _loadDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('fcm_device_id');
    if (saved != null) return saved;
    final random = Random.secure();
    final id = base64UrlEncode(List.generate(24, (_) => random.nextInt(256)));
    await prefs.setString('fcm_device_id', id);
    return id;
  }

  Future<void> register(String token) async {
    if (!canSync) return;
    await api.post(
      AppConfig.fcmTokenPath,
      body: {'token': token, 'dispositivo_id': await deviceId()},
    );
  }

  Future<void> remove() async {
    if (!canSync) return;
    await api.delete(
      '${AppConfig.fcmTokenPath}?dispositivo_id=${Uri.encodeComponent(await deviceId())}',
    );
  }

  Future<Map<String, dynamic>> test() async {
    final response = await api.post(
      '${AppConfig.fcmTokenPath}/teste',
      body: {},
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
