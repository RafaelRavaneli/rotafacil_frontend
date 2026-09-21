import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  Uri _uri(String path) {
    final baseUrl = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;

    final route = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$baseUrl$route');
  }

  Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final token = SessionService.instance.token;

    if (auth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, String> _multipartHeaders({bool auth = true}) {
    final headers = <String, String>{'Accept': 'application/json'};

    final token = SessionService.instance.token;

    if (auth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // GET - buscar dados
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool auth = true,
  }) async {
    var uri = _uri(path);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await http.get(uri, headers: _headers(auth: auth));

    return _decode(response);
  }

  // POST - criar/enviar dados
  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );

    return _decode(response);
  }

  // PUT - substituir/atualizar dados
  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    final response = await http.put(
      _uri(path),
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );

    return _decode(response);
  }

  // PATCH - atualizar somente alguns campos
  Future<dynamic> patch(String path, {Object? body, bool auth = true}) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );

    return _decode(response);
  }

  // DELETE - excluir dados
  Future<dynamic> delete(String path, {bool auth = true}) async {
    final response = await http.delete(
      _uri(path),
      headers: _headers(auth: auth),
    );

    return _decode(response);
  }

  // MULTIPART - enviar foto/arquivo
  Future<dynamic> uploadMultipart(
    String path, {
    required Uint8List bytes,
    required String fileName,
    String fieldName = 'file',
    Map<String, String>? fields,
    bool auth = true,
    String method = 'POST',
  }) async {
    final request = http.MultipartRequest(method.toUpperCase(), _uri(path));

    request.headers.addAll(_multipartHeaders(auth: auth));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    dynamic data;

    try {
      data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      data = <String, dynamic>{'erro': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String message = 'Erro na comunicação com a API';

    if (data is Map) {
      message = (data['erro'] ?? data['mensagem'] ?? data['message'] ?? message)
          .toString();
    }

    throw ApiException(message, response.statusCode);
  }
}
