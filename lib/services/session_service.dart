import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SessionEndReason { logout, expired, externalLogout }

class SessionService extends ChangeNotifier {
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
  SessionEndReason? _endReason;

  SessionEndReason? consumeEndReason() {
    final reason = _endReason;
    _endReason = null;
    return reason;
  }

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
    _endReason = null;

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

  Future<void> clear({
    SessionEndReason reason = SessionEndReason.logout,
  }) async {
    token = null;
    role = null;
    email = null;
    userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userIdKey);

    _endReason = reason;
    notifyListeners();
  }

  Future<bool> synchronizeFromStorage() async {
    final hadSession =
        (role?.isNotEmpty ?? false) && (email?.isNotEmpty ?? false);
    if (!hadSession) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final storedRole = prefs.getString(_roleKey);
    final storedEmail = prefs.getString(_emailKey);
    final storedToken = prefs.getString(_tokenKey);

    final sessionWasRemoved =
        storedRole == null ||
        storedRole.isEmpty ||
        storedEmail == null ||
        storedEmail.isEmpty ||
        ((token?.isNotEmpty ?? false) &&
            (storedToken == null || storedToken.isEmpty));
    if (!sessionWasRemoved) return false;

    token = null;
    role = null;
    email = null;
    userId = null;
    _endReason = SessionEndReason.externalLogout;
    notifyListeners();
    return true;
  }
}
