import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/models/user_role.dart';
import 'package:rotafacil/pages/auth/login_screen.dart';
import 'package:rotafacil/pages/auth/register_screen.dart';
import 'package:rotafacil/pages/auth/welcome_screen.dart';
import 'package:rotafacil/pages/common/bookings_screen.dart';
import 'package:rotafacil/pages/common/favorites_screen.dart';
import 'package:rotafacil/pages/common/profile_tab.dart';
import 'package:rotafacil/pages/tourist/tourist_home_tab.dart';
import 'package:rotafacil/pages/tourist/trail_search_screen.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quem aumenta a fonte do sistema (acessibilidade) não pode ver conteúdo
/// cortado. Cada tela é aberta com a fonte a 200% em um celular pequeno.
Future<List<String>> _overflows(
  WidgetTester tester,
  Widget screen, {
  double scale = 2,
  Size size = const Size(360, 740),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString();
    final first = text
        .split('\n')
        .firstWhere((l) => l.contains('overflowed'), orElse: () => text);
    // Aponta o arquivo da tela que estourou, para facilitar a correção.
    final where = RegExp(r'file:///\S+').firstMatch(text)?.group(0) ?? '';
    errors.add('$first ($where)');
  };
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  // Devolve o handler e desmonta a tela (timers pendentes) antes do fim do teste.
  FlutterError.onError = previous;
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  return errors.where((e) => e.contains('overflowed')).toList();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStore.instance.initialize();
  });

  final screens = <String, Widget Function()>{
    'Tela inicial': () => const WelcomeScreen(),
    'Login': () => const LoginScreen(),
    'Cadastro (turista)': () => const RegisterScreen(role: UserRole.tourist),
    'Home do turista': () => Scaffold(
      body: TouristHomeTab(hasLocationPermission: () async => false),
    ),
    'Busca': () => const TrailSearchScreen(),
    'Perfil': () => const Scaffold(body: ProfileTab()),
    'Reservas': () => const Scaffold(body: BookingsScreen(role: 'turista')),
    'Favoritos': () => const Scaffold(body: FavoritesScreen()),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} não estoura com fonte a 200%', (tester) async {
      final overflows = await _overflows(tester, entry.value());
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  }
}
