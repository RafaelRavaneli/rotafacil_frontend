import 'package:flutter/material.dart';
import 'auth_page_route.dart';
import 'app_routes.dart';
import '../pages/agency/agency_shell.dart';
import '../pages/admin/admin_shell.dart';
import '../pages/guide/guide_shell.dart';
import '../pages/tourist/tourist_shell.dart';
import '../state/app_store.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

Future<void> enterAuthenticatedHome(BuildContext context, String role) async {
  await AppStore.instance.refreshBackend();
  if (!context.mounted) return;
  if (role == 'usuario') {
    try {
      await LocationService.instance.capture();
    } catch (_) {}
  }
  try {
    await NotificationService.instance.registerAfterLogin();
  } catch (_) {}
  if (!context.mounted) return;
  final destination = switch (role) {
    'usuario' => const TouristShell(),
    'guia' => const GuideShell(),
    'agencia' => const AgencyShell(),
    'admin' => const AdminShell(),
    _ => throw StateError('Perfil não suportado.'),
  };
  Navigator.of(context).pushAndRemoveUntil(
    AuthPageRoute<void>(
      settings: RouteSettings(name: AppRoutes.homeForRole(role)),
      builder: (_) => destination,
    ),
    (_) => false,
  );
}
