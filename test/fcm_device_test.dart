import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/fcm_token_api.dart';
import 'package:rotafacil/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Registro e logout usam a mesma instalação persistida', () async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.instance.save(
      authToken: 'test',
      selectedRole: 'usuario',
      userEmail: 'test@example.test',
      id: 't',
    );
    String? registered;
    var removed = false;
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test');
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map;
          expect(body['token'], 'test-token');
          registered = body['dispositivo_id'] as String;
        } else {
          expect(request.url.queryParameters['dispositivo_id'], registered);
          removed = true;
        }
        return http.Response('{}', 200);
      }),
    );
    final first = FcmTokenApi(api: api);
    await first.register('test-token');
    final restored = FcmTokenApi(api: api);
    expect(await restored.deviceId(), registered);
    await restored.remove();
    expect(removed, isTrue);
    await SessionService.instance.clear();
  }, skip: !AppConfig.useBackend);
}
