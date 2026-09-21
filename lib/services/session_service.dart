import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _tokenKey = 'session_token';
  static const _roleKey = 'session_role';
  static const _emailKey = 'session_email';
  static const _userIdKey = 'session_user_id';

  String? token;
  String? role;
  String? email;
  String? userId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    role = prefs.getString(_roleKey);
    email = prefs.getString(_emailKey);
    userId = prefs.getString(_userIdKey);
  }

  Future<void> save({
    String? authToken,
    required String selectedRole,
    required String userEmail,
    String? id,
  }) async {
    token = authToken;
    role = selectedRole;
    email = userEmail;
    userId = id;

    final prefs = await SharedPreferences.getInstance();

    if (authToken == null || authToken.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, authToken);
    }

    await prefs.setString(_roleKey, selectedRole);
    await prefs.setString(_emailKey, userEmail);

    if (id == null || id.isEmpty) {
      await prefs.remove(_userIdKey);
    } else {
      await prefs.setString(_userIdKey, id);
    }
  }

  Future<void> clear() async {
    token = null;
    role = null;
    email = null;
    userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userIdKey);
  }
}
