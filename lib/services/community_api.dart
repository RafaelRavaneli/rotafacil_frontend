import 'api_client.dart';

class CommunityApi {
  CommunityApi({ApiClient? api}) : api = api ?? ApiClient.instance;
  final ApiClient api;

  Future<List<Map<String, dynamic>>> list(String path) async {
    final result = await api.get(path);
    if (result is! List) throw const FormatException('Resposta inválida.');
    return result.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<Map<String, dynamic>> create(
    String path,
    Map<String, dynamic> body,
  ) async {
    final result = await api.post(path, body: body);
    if (result is! Map) throw const FormatException('Resposta inválida.');
    return Map<String, dynamic>.from(result);
  }

  Future<void> answer(String id, String status) async {
    await api.put(
      '/api/convites-guias/${Uri.encodeComponent(id)}',
      body: {'status': status},
    );
  }
}
