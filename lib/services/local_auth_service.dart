import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/document_validator.dart';
import '../utils/role_utils.dart';

class LocalAuthService {
  LocalAuthService._();

  static final LocalAuthService instance = LocalAuthService._();

  static const _accountsKey = 'local_accounts_v4';

  String _roleKey(String role) => normalizeRoleKey(role);

  String _hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<Map<String, dynamic>> _accounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }

    final seeded = <String, dynamic>{
      'turista': {
        'email': 'thiago@email.com',
        'passwordHash': _hash('123456'),
        'document': '',
      },
      'guia': {
        'email': 'guia@email.com',
        'passwordHash': _hash('123456'),
        'document': '52998224725',
      },
      'agencia': {
        'email': 'contato@aventuraprime.com',
        'passwordHash': _hash('123456'),
        'document': '11222333000181',
      },
    };

    await prefs.setString(_accountsKey, jsonEncode(seeded));

    return seeded;
  }

  String? _accountKey(Map<String, dynamic> accounts, String email) {
    final normalized = email.trim().toLowerCase();
    final matches = accounts.entries
        .where(
          (entry) =>
              entry.value is Map &&
              (entry.value as Map)['email']?.toString().trim().toLowerCase() ==
                  normalized,
        )
        .toList();
    // Contas antigas com e-mails repetidos não podem selecionar um perfil arbitrário.
    return matches.length == 1 ? matches.single.key : null;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final accounts = await _accounts();
    final key = _accountKey(accounts, email);
    if (key == null) return null;
    final account = Map<String, dynamic>.from(accounts[key] as Map);
    return account['passwordHash'] == _hash(password) ? key : null;
  }

  Future<void> register({
    required String role,
    required String email,
    required String password,
    String document = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _accounts();
    final key = _roleKey(role);

    if (accounts.entries.any(
      (entry) =>
          entry.key != key &&
          entry.value is Map &&
          (entry.value as Map)['email']?.toString().trim().toLowerCase() ==
              email.trim().toLowerCase(),
    )) {
      throw StateError('E-mail já cadastrado. Faça login com sua conta.');
    }
    accounts[key] = {
      'email': email.trim(),
      'passwordHash': _hash(password),
      'document': DocumentValidator.digitsOnly(document),
    };

    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<void> updateEmail({
    required String role,
    required String newEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _accounts();
    final key = _roleKey(role);
    final rawAccount = accounts[key];

    if (rawAccount is! Map) return;

    final account = Map<String, dynamic>.from(rawAccount);

    account['email'] = newEmail.trim();
    accounts[key] = account;

    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<void> updateDocument({
    required String role,
    required String document,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _accounts();
    final key = _roleKey(role);
    final rawAccount = accounts[key];

    if (rawAccount is! Map) return;

    final account = Map<String, dynamic>.from(rawAccount);

    account['document'] = DocumentValidator.digitsOnly(document);

    accounts[key] = account;

    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<bool> changePassword({
    required String role,
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _accounts();
    final key = _roleKey(role);
    final rawAccount = accounts[key];

    if (rawAccount is! Map) return false;

    final account = Map<String, dynamic>.from(rawAccount);

    if (account['passwordHash'] != _hash(currentPassword)) {
      return false;
    }

    account['passwordHash'] = _hash(newPassword);
    accounts[key] = account;

    await prefs.setString(_accountsKey, jsonEncode(accounts));

    return true;
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _accounts();
    final key = _accountKey(accounts, email);
    if (key == null) throw StateError('Conta não encontrada.');
    final rawAccount = accounts[key];

    if (rawAccount is! Map) {
      throw StateError('Conta não encontrada.');
    }

    final account = Map<String, dynamic>.from(rawAccount);

    if (account['email']?.toString().toLowerCase() !=
        email.trim().toLowerCase()) {
      throw StateError('E-mail não encontrado.');
    }

    account['passwordHash'] = _hash(newPassword);
    accounts[key] = account;

    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }
}
