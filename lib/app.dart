import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'pages/agency/agency_shell.dart';
import 'pages/auth/welcome_screen.dart';
import 'pages/guide/guide_shell.dart';
import 'pages/tourist/tourist_shell.dart';
import 'services/session_service.dart';
import 'state/app_store.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class RotaFacilApp extends StatelessWidget {
  const RotaFacilApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      title: 'RotaFácil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _SessionBootstrap(),
    );
  }
}

class _SessionBootstrap extends StatefulWidget {
  const _SessionBootstrap();

  @override
  State<_SessionBootstrap> createState() =>
      _SessionBootstrapState();
}

class _SessionBootstrapState
    extends State<_SessionBootstrap> {
  late Future<Widget> _bootstrapFuture;

  @override
  void initState() {
    super.initState();

    _bootstrapFuture = _resolveInitialScreen();
  }

  Future<Widget> _resolveInitialScreen() async {
    try {
      await AppStore.instance.initialize();

      await SessionService.instance.initialize();

      final session = SessionService.instance;

      final role =
          session.role?.trim().toLowerCase() ?? '';

      final email =
          session.email?.trim() ?? '';

      // Não existe uma sessão salva.
      if (role.isEmpty || email.isEmpty) {
        return const WelcomeScreen();
      }

      // Quando o backend estiver ativo,
      // uma sessão válida precisa possuir token.
      if (AppConfig.useBackend) {
        final token =
            session.token?.trim() ?? '';

        if (token.isEmpty) {
          await session.clear();

          return const WelcomeScreen();
        }
      }

      switch (role) {
        case 'turista':
        case 'usuario':
        case 'tourist':
          return const TouristShell();

        case 'guia':
        case 'guide':
          return const GuideShell();

        case 'agencia':
        case 'agência':
        case 'agency':
          return const AgencyShell();

        default:
          // Sessão antiga, corrompida ou com perfil
          // desconhecido.
          await session.clear();

          return const WelcomeScreen();
      }
    } catch (_) {
      // Se houver problema ao restaurar a sessão,
      // o aplicativo continua abrindo normalmente.
      return const WelcomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _bootstrapFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<Widget> snapshot,
      ) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return snapshot.data ??
            const WelcomeScreen();
      },
    );
  }
}