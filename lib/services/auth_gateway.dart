import 'dart:convert';

import '../config/app_config.dart';
import '../models/user_role.dart';
import '../utils/document_validator.dart';
import '../utils/cadastur_validator.dart';
import 'legal_documents.dart';
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
    this.requiresEmailConfirmation = false,
    this.confirmationSent = false,
  });

  final String role;
  final String name;
  final String email;
  final String? userId;
  final bool fromBackend;
  final bool requiresEmailConfirmation;
  final bool confirmationSent;
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
    if (!{'usuario', 'guia', 'agencia', 'admin'}.contains(role)) {
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
    String cadasturNumber = '',
    String cadasturValidUntil = '',
    bool acceptedLegal = false,
  }) async {
    if (!acceptedLegal) {
      throw StateError(
        'Leia e aceite os Termos de Uso e a Política de Privacidade.',
      );
    }
    if (role == UserRole.guide || role == UserRole.agency) {
      final error = CadasturValidator.error(cadasturNumber);
      if (error != null) throw StateError(error);
    }
    final legalAcceptance = await LegalDocuments.acceptance();
    if (!AppConfig.useBackend) {
      await LocalAuthService.instance.register(
        role: role.title,
        email: email,
        password: password,
        document: document,
        legalAcceptance: legalAcceptance,
      );

      return AuthRegisterResult(
        role: role.title,
        name: name.trim(),
        email: email.trim(),
        fromBackend: false,
      );
    }

    final body = <String, dynamic>{
      ...legalAcceptance,
      'nome': name,
      'email': email,
      'senha': password,
      'telefone': phone,
      'cidade': city,
      'estado': state,
      'tipo': role.apiValue,
      if (role != UserRole.tourist) ...{
        'cadastur_numero': CadasturValidator.normalize(cadasturNumber),
        'cadastur_validade': cadasturValidUntil,
      },
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
      requiresEmailConfirmation: data['confirmacao_email_necessaria'] == true,
      confirmationSent: data['confirmacao_email_enviada'] == true,
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

  Future<void> requestEmailConfirmation(String email) async {
    await _api.post(
      '/api/auth/email/solicitar',
      auth: false,
      body: {'email': email.trim().toLowerCase()},
    );
  }

  Future<void> confirmEmail(String email, String token) async {
    await _api.post(
      '/api/auth/email/confirmar',
      auth: false,
      body: {'email': email.trim().toLowerCase(), 'token': token.trim()},
    );
  }

  Future<AuthLoginResult> confirmEmailAndLogin(
    String email,
    String token,
  ) async {
    final data = await _api.post(
      '/api/auth/email/confirmar',
      auth: false,
      body: {
        'email': email.trim().toLowerCase(),
        'token': token.trim(),
        'iniciar_sessao': true,
      },
    );
    return _saveLinkSession(data);
  }

  Future<AuthLoginResult> resetPasswordAndLogin({
    required String token,
    required String newPassword,
  }) async {
    final data = await _api.post(
      '/api/auth/senha/redefinir',
      auth: false,
      body: {
        'token': token.trim(),
        'nova_senha': newPassword,
        'iniciar_sessao': true,
      },
    );
    return _saveLinkSession(data);
  }

  Future<AuthLoginResult> _saveLinkSession(dynamic data) async {
    if (data is! Map ||
        !{'usuario', 'guia', 'agencia', 'admin'}.contains(data['tipo']) ||
        data['token'] is! String ||
        (data['token'] as String).isEmpty ||
        data['email'] is! String ||
        (data['email'] as String).isEmpty ||
        data['id'] is! String ||
        (data['id'] as String).isEmpty) {
      throw StateError(
        'Não foi possível iniciar a sessão. Faça login com sua senha.',
      );
    }
    await SessionService.instance.save(
      authToken: data['token'] as String,
      selectedRole: data['tipo'] as String,
      userEmail: data['email'] as String,
      id: data['id'] as String,
    );
    return AuthLoginResult(
      role: data['tipo'] as String,
      email: data['email'] as String,
      name: data['nome']?.toString(),
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

  Future<void> changePassword({
    required String role,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!AppConfig.useBackend) {
      final changed = await LocalAuthService.instance.changePassword(
        role: role,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!changed) throw StateError('Senha atual incorreta.');
      return;
    }

    await _api.put(
      '/api/auth/senha',
      body: {'senha_atual': currentPassword, 'nova_senha': newPassword},
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
