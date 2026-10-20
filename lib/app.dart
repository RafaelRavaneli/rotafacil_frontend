import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_config.dart';
import 'pages/agency/agency_shell.dart';
import 'pages/admin/admin_shell.dart';
import 'pages/auth/welcome_screen.dart';
import 'pages/auth/login_screen.dart';
import 'pages/auth/account_link_screen.dart';
import 'pages/auth/verify_email_screen.dart';
import 'pages/auth/forgot_password_screen.dart';
import 'pages/common/legal_document_screen.dart';
import 'pages/common/booking_details_screen.dart';
import 'pages/common/trail_participants_screen.dart';
import 'pages/guide/guide_shell.dart';
import 'pages/management/trail_form_screen.dart';
import 'pages/tourist/trail_details_screen.dart';
import 'pages/tourist/trail_search_screen.dart';
import 'pages/tourist/tourist_shell.dart';
import 'navigation/app_routes.dart';
import 'services/session_service.dart';
import 'services/api_client.dart';
import 'state/app_store.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class RotaFacilApp extends StatefulWidget {
  const RotaFacilApp({super.key});

  @override
  State<RotaFacilApp> createState() => _RotaFacilAppState();
}

class _RotaFacilAppState extends State<RotaFacilApp>
    with WidgetsBindingObserver {
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SessionService.instance.addListener(_handleSessionEnd);
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(SessionService.instance.synchronizeFromStorage()),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SessionService.instance.removeListener(_handleSessionEnd);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !AppConfig.useBackend) return;
    if (SessionService.instance.userId?.isNotEmpty != true) return;
    unawaited(AppStore.instance.refreshBackend());
  }

  void _handleSessionEnd() {
    final reason = SessionService.instance.consumeEndReason();
    if (reason != SessionEndReason.expired &&
        reason != SessionEndReason.externalLogout) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            reason == SessionEndReason.expired
                ? 'Sua sessão expirou. Entre novamente.'
                : 'A sessão foi encerrada em outra aba.',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      title: 'RotaFácil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        final media = MediaQuery.maybeOf(context);
        if (media == null || child == null) return child ?? const SizedBox();
        return MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: true),
          child: child,
        );
      },
      onGenerateInitialRoutes: (location) => [
        _buildRoute(RouteSettings(name: location)),
      ],
      onGenerateRoute: _buildRoute,
    );
  }

  Route<void> _buildRoute(RouteSettings settings) {
    final location = settings.name ?? AppRoutes.welcome;
    final uri = Uri.tryParse(location) ?? Uri();
    final path = uri.path;
    if (path == '/confirmar-email' || path == '/redefinir-senha') {
      return MaterialPageRoute<void>(
        settings: RouteSettings(name: path),
        builder: (_) => AccountLinkScreen(
          email: uri.queryParameters['email'] ?? '',
          token: uri.queryParameters['token'] ?? '',
          recoverPassword: path == '/redefinir-senha',
        ),
      );
    }
    if (path == '/verificar-email' || path == '/recuperar-senha') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => path == '/verificar-email'
            ? const VerifyEmailScreen()
            : const ForgotPasswordScreen(),
      );
    }
    final page = path == '/termos' || path == '/privacidade'
        ? LegalDocumentScreen(
            documentKey: path == '/termos' ? 'termos' : 'privacidade',
          )
        : location == AppRoutes.login
        ? const LoginScreen()
        : _SessionBootstrap(initialLocation: location);
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}

class _SessionBootstrap extends StatefulWidget {
  const _SessionBootstrap({required this.initialLocation});

  final String initialLocation;

  @override
  State<_SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends State<_SessionBootstrap> {
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

      final role = session.role?.trim().toLowerCase() ?? '';

      final email = session.email?.trim() ?? '';

      // Não existe uma sessão salva.
      if (role.isEmpty || email.isEmpty) {
        return const WelcomeScreen();
      }

      // Quando o backend estiver ativo,
      // uma sessão válida precisa possuir token.
      if (AppConfig.useBackend) {
        final token = session.token?.trim() ?? '';

        if (token.isEmpty) {
          await session.clear();

          return const WelcomeScreen();
        }
      }

      if (AppConfig.useBackend) await AppStore.instance.refreshBackend();

      return await _screenForRole(role);
    } on ApiException catch (error) {
      if (error.statusCode == 401) await SessionService.instance.clear();
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  Future<Widget> _screenForRole(String role) async {
    final uri = Uri.tryParse(widget.initialLocation) ?? Uri();
    final segments = uri.pathSegments;

    if (segments.length == 2 && segments.first == 'roteiro') {
      final id = Uri.decodeComponent(segments[1]);
      final trail = AppStore.instance.trails
          .where((item) => item.id == id)
          .firstOrNull;
      if (trail != null) return TrailDetailsScreen(trail: trail);
    }
    if (segments.length == 2 && segments.first == 'reserva') {
      return BookingDetailsScreen(bookingId: Uri.decodeComponent(segments[1]));
    }
    if (uri.path == AppRoutes.search) return const TrailSearchScreen();

    final isAgency = role == 'agencia' || role == 'agência' || role == 'agency';
    if (uri.path == AppRoutes.newTrail && (isAgency || role == 'guia')) {
      return TrailFormScreen(isAgency: isAgency);
    }
    if (segments.length == 3 &&
        segments.first == 'roteiros' &&
        segments.last == 'editar' &&
        (isAgency || role == 'guia')) {
      final id = Uri.decodeComponent(segments[1]);
      final trail = AppStore.instance.managedTrails
          .where((item) => item.id == id)
          .firstOrNull;
      if (trail != null) {
        return TrailFormScreen(isAgency: isAgency, existing: trail);
      }
    }
    if (segments.length == 3 &&
        segments.first == 'roteiros' &&
        segments.last == 'inscritos' &&
        (isAgency || role == 'guia')) {
      final id = Uri.decodeComponent(segments[1]);
      final trail = AppStore.instance.managedTrails
          .where((item) => item.id == id)
          .firstOrNull;
      if (trail != null) return TrailParticipantsScreen(trail: trail);
    }

    final initialIndex = AppRoutes.tabIndex(widget.initialLocation, role);
    switch (role) {
      case 'turista':
      case 'usuario':
      case 'tourist':
        return TouristShell(initialIndex: initialIndex);

      case 'guia':
      case 'guide':
        return GuideShell(initialIndex: initialIndex);

      case 'agencia':
      case 'agência':
      case 'agency':
        return AgencyShell(initialIndex: initialIndex);

      case 'admin':
        return const AdminShell();

      default:
        await SessionService.instance.clear();
        return const WelcomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _bootstrapFuture,
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não foi possível carregar sua conta.'),
                  FilledButton(
                    onPressed: () => setState(() {
                      _bootstrapFuture = _resolveInitialScreen();
                    }),
                    child: const Text('Tentar novamente'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await SessionService.instance.clear();
                      if (mounted) {
                        setState(() {
                          _bootstrapFuture = Future.value(
                            const WelcomeScreen(),
                          );
                        });
                      }
                    },
                    child: const Text('Voltar ao login'),
                  ),
                ],
              ),
            ),
          );
        }
        return snapshot.data ?? const WelcomeScreen();
      },
    );
  }
}
