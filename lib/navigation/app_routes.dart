import '../services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppRoutes {
  const AppRoutes._();

  static const welcome = '/';
  static const login = '/login';
  static const search = '/buscar';

  static String trail(String id) => '/roteiro/${Uri.encodeComponent(id)}';
  static String booking(String id) => '/reserva/${Uri.encodeComponent(id)}';
  static String newTrail = '/roteiros/novo';
  static String editTrail(String id) =>
      '/roteiros/${Uri.encodeComponent(id)}/editar';
  static String trailParticipants(String id) =>
      '/roteiros/${Uri.encodeComponent(id)}/inscritos';

  static List<String> tabsForRole(String role) => switch (role) {
    'turista' ||
    'usuario' ||
    'tourist' => const ['/explorar', '/favoritos', '/reservas', '/perfil'],
    'guia' || 'guide' => const ['/painel', '/roteiros', '/agenda', '/perfil'],
    'agencia' ||
    'agência' ||
    'agency' => const ['/painel', '/roteiros', '/guias', '/agenda', '/perfil'],
    _ => const ['/'],
  };

  static int tabIndex(String location, String role) {
    final path = Uri.tryParse(location)?.path ?? welcome;
    final index = tabsForRole(role).indexOf(path);
    return index < 0 ? 0 : index;
  }

  static String homeForRole(String role) => tabsForRole(role).first;

  static Future<void> replaceBrowserLocation(String path) {
    return SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(path),
      replace: true,
    );
  }

  /// Preserva a pilha normal e oferece uma saída para páginas abertas pela URL.
  /// maybePop também respeita PopScope e confirmações de dados não salvos.
  static Future<void> back(
    BuildContext context, {
    String? fallbackLocation,
  }) async {
    final navigator = Navigator.of(context);
    if (await navigator.maybePop()) return;
    if (!context.mounted) return;
    navigator.pushReplacementNamed(
      fallbackLocation ?? homeForRole(SessionService.instance.role ?? ''),
    );
  }

  static String get bookingListLocation {
    final role = SessionService.instance.role ?? '';
    return const [
          'guia',
          'guide',
          'agencia',
          'agência',
          'agency',
        ].contains(role)
        ? '/agenda'
        : '/reservas';
  }

  static Future<T?> push<T>(
    BuildContext context,
    String path,
    WidgetBuilder builder,
  ) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute<T>(
        settings: RouteSettings(name: path),
        builder: builder,
      ),
    );
  }
}
