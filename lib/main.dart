import 'package:flutter/material.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/session_service.dart';
import 'state/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppStore.instance.initialize();
  await SessionService.instance.initialize();

  await NotificationService.instance.initialize();

  runApp(const RotaFacilApp());
}
