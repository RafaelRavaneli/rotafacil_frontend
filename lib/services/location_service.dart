import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserCoordinates {
  const UserCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationService {
  LocationService._();

  static final instance = LocationService._();

  static const _permissionKey = 'location_permission_status';
  static const _latitudeKey = 'last_location_latitude';
  static const _longitudeKey = 'last_location_longitude';
  Future<UserCoordinates>? _captureInFlight;
  UserCoordinates? _recent;
  DateTime? _capturedAt;

  Future<UserCoordinates?> cached() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);
    if (latitude == null || longitude == null) return null;
    return UserCoordinates(latitude: latitude, longitude: longitude);
  }

  Future<String?> savedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_permissionKey);
  }

  Future<UserCoordinates> capture({bool requestPermission = true}) async {
    final recent = _recent;
    if (recent != null &&
        _capturedAt != null &&
        DateTime.now().difference(_capturedAt!) < const Duration(minutes: 1)) {
      return recent;
    }
    final active = _captureInFlight;
    if (active != null) return active;
    final capture = _capture(requestPermission: requestPermission);
    _captureInFlight = capture;
    try {
      final result = await capture;
      _recent = result;
      _capturedAt = DateTime.now();
      return result;
    } finally {
      if (identical(_captureInFlight, capture)) _captureInFlight = null;
    }
  }

  Future<UserCoordinates> _capture({required bool requestPermission}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
        'Ative a localização do dispositivo para ver atividades próximas.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_permissionKey, permission.name);

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'A localização está bloqueada. Libere a permissão nas configurações do navegador.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw StateError(
        'Permissão de localização negada. Autorize o acesso e tente novamente.',
      );
    }

    final position = await Geolocator.getCurrentPosition().timeout(
      const Duration(seconds: 12),
    );
    await prefs.setDouble(_latitudeKey, position.latitude);
    await prefs.setDouble(_longitudeKey, position.longitude);
    return UserCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
