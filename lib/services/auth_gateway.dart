import 'dart:convert';

import '../config/app_config.dart';
import '../models/user_role.dart';
import '../utils/document_validator.dart';
import 'api_client.dart';
import 'local_auth_service.dart';
import 'session_service.dart';

class AuthLoginResult {
  const AuthLoginResult({required this.role, required this.email, this.name});

  final String role;
  final String email;
  final String? name;
}

class AuthRegisterResult {
  const AuthRegisterResult({
    required this.role,
    required this.name,
    required this.email,
    required this.fromBackend,
    this.userId,
  });

  final String role;
  final String name;
  final String email;
  final String? userId;
  final bool fromBackend;
}

class AuthGateway {
  AuthGateway({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  static final AuthGateway instance = AuthGateway();

  Future<AuthLoginResult?> login({
    required String email,
    required String password,
  }) async {
    if (!AppConfig.useBackend) {
      final localRole = await LocalAuthService.instance.login(
        email: email,
        password: password,
      );

      if (localRole == null) return null;
      final role = localRole == 'turista' ? 'usuario' : localRole;

      await SessionService.instance.save(selectedRole: role, userEmail: email);

      return AuthLoginResult(role: role, email: email);
    }

    final body = <String, dynamic>{'email': email, 'senha': password};

    final data = await _api.post('/api/auth/login', auth: false, body: body);

    if (data is! Map) {
      throw StateError('Resposta inválida do login.');
    }

    final token = data['token']?.toString();

    final role = data['tipo']?.toString().trim().toLowerCase();
    if (!{'usuario', 'guia', 'agencia'}.contains(role)) {
      throw StateError('A conta retornou um perfil não suportado.');
    }

    final name = data['nome']?.toString();

    if (token == null || token.isEmpty) {
      throw StateError('A API não retornou o token JWT.');
    }

    final userId = _extractUserId(data, token);

    await SessionService.instance.save(
      authToken: token,
      selectedRole: role!,
      userEmail: email,
      id: userId,
    );

    return AuthLoginResult(role: role, email: email, name: name);
  }

  Future<AuthRegisterResult> register({
    required UserRole role,
    required String name,
    required String email,
    required String password,
    String? phone,
    String? city,
    String? state,
    String document = '',
  }) async {
    if (!AppConfig.useBackend) {
      await LocalAuthService.instance.register(
        role: role.title,
        email: email,
        password: password,
        document: document,
      );

      return AuthRegisterResult(
        role: role.title,
        name: name.trim(),
        email: email.trim(),
        fromBackend: false,
      );
    }

    final body = <String, dynamic>{
      'nome': name,
      'email': email,
      'senha': password,
      'telefone': phone,
      'cidade': city,
      'estado': state,
      'tipo': role.apiValue,
    };

    if (role == UserRole.guide) {
      body['documento'] = DocumentValidator.digitsOnly(document);
    }

    if (role == UserRole.agency) {
      body['documento'] = DocumentValidator.digitsOnly(document);
    }

    final data = await _api.post('/api/usuarios/', auth: false, body: body);

    if (data is! Map) {
      return AuthRegisterResult(
        role: role.apiValue,
        name: name.trim(),
        email: email.trim(),
        fromBackend: true,
      );
    }

    final responseId = data['id'] ?? data['id_usuario'] ?? data['usuario_id'];

    final responseName = (data['nome'] ?? data['name'])?.toString().trim();

    final responseEmail = data['email']?.toString().trim();

    final responseRole = (data['tipo'] ?? data['role'])?.toString().trim();

    return AuthRegisterResult(
      role: responseRole == null || responseRole.isEmpty
          ? role.apiValue
          : responseRole,
      name: responseName == null || responseName.isEmpty
          ? name.trim()
          : responseName,
      email: responseEmail == null || responseEmail.isEmpty
          ? email.trim()
          : responseEmail,
      userId: responseId == null || responseId.toString().trim().isEmpty
          ? null
          : responseId.toString(),
      fromBackend: true,
    );
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
    String token = '',
  }) async {
    final normalizedEmail = email.trim();

    if (!AppConfig.useBackend) {
      await LocalAuthService.instance.resetPassword(
        email: normalizedEmail,
        newPassword: newPassword,
      );

      return;
    }

    if (token.trim().isEmpty) {
      throw StateError('Informe o código de redefinição recebido por e-mail.');
    }

    await _api.post(
      '/api/auth/senha/redefinir',
      auth: false,
      body: {'token': token.trim(), 'nova_senha': newPassword},
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _api.post(
      '/api/auth/senha/solicitar',
      auth: false,
      body: {'email': email.trim()},
    );
  }

  String? _extractUserId(Map<dynamic, dynamic> data, String token) {
    final responseId = data['id'] ?? data['id_usuario'] ?? data['usuario_id'];

    if (responseId != null && responseId.toString().trim().isNotEmpty) {
      return responseId.toString();
    }

    const possibleClaims = <String>[
      'id',
      'id_usuario',
      'usuario_id',
      'user_id',
      'sub',
    ];

    for (final claim in possibleClaims) {
      final value = _jwtClaim(token, claim);

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }

  dynamic _jwtClaim(String token, String key) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return null;
      }

      final normalized = base64Url.normalize(parts[1]);

      final payload = utf8.decode(base64Url.decode(normalized));

      final decoded = jsonDecode(payload);

      if (decoded is Map) {
        return decoded[key];
      }
    } catch (_) {}

    return null;
  }
}
