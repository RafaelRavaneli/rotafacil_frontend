import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/widgets/trail_results_map.dart';
import 'package:rotafacil/widgets/brazil_location_fields.dart';
import 'package:rotafacil/widgets/auth_scaffold.dart';
import 'package:rotafacil/widgets/animated_tab_body.dart';
import 'package:rotafacil/pages/auth/account_link_screen.dart';
import 'package:rotafacil/services/auth_gateway.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/session_service.dart';
import 'package:rotafacil/navigation/app_routes.dart';
import 'package:rotafacil/app.dart';

class _Tiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('assets/images/auth_background.png');
}

void main() {
  for (final path in ['/confirmar-email', '/redefinir-senha']) {
    testWidgets(
      'Link direto $path abre sem login e não guarda segredo no nome da rota',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await SessionService.instance.clear();
        tester.binding.platformDispatcher.defaultRouteNameTestValue =
            '$path?email=p%40example.test&token=${'a' * 43}';
        addTearDown(
          tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
        );
        await tester.pumpWidget(const RotaFacilApp());
        await tester.pumpAndSettle();
        final finder = find.byType(AccountLinkScreen);
        expect(finder, findsOneWidget);
        expect(
          tester.widget<AccountLinkScreen>(finder).email,
          'p@example.test',
        );
        expect(ModalRoute.of(tester.element(finder))!.settings.name, path);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  Trail trail(String id, double latitude) => Trail.fromJson({
    'id': id,
    'nome': 'Roteiro $id',
    'latitude': latitude,
    'longitude': -51.9,
  });

  test('Agrupamento mantém todos os roteiros e separa próximos ao ampliar', () {
    final trails = [trail('a', -23.4), trail('b', -23.4001), trail('c', -24.4)];
    expect(groupTrailMarkers(trails, 12).map((group) => group.trails.length), [
      2,
      1,
    ]);
    expect(groupTrailMarkers(trails, 21).length, 3);
    expect(
      groupTrailMarkers([
        trails.first,
        trail('igual', -23.4),
      ], 21).single.trails.length,
      2,
    );
    expect(
      groupTrailMarkers([
        ...trails,
        Trail.fromJson({'id': 'sem'}),
      ], 12).expand((group) => group.trails).length,
      3,
    );
  });

  testWidgets('UF fica à esquerda e mantém espaço e contraste no mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = TextEditingController(text: 'PR');
    final city = TextEditingController(text: 'Maringá');
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScaffold(
          title: 'Cadastro',
          body: BrazilLocationFields(
            city: city,
            state: state,
            labelsAbove: true,
          ),
        ),
      ),
    );
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.first.controller, state);
    expect(fields.last.controller, city);
    expect(
      tester.getTopLeft(find.byType(TextField).first).dx,
      lessThan(tester.getTopLeft(find.byType(TextField).last).dx),
    );
    expect(
      tester.getSize(find.byType(EditableText).first).width,
      greaterThan(30),
    );
    expect(fields.first.style!.color, const Color(0xFF25332C));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    city.dispose();
  });

  testWidgets('Troca rápida de abas não mantém telas antigas sobrepostas', (
    tester,
  ) async {
    for (var index = 0; index < 4; index++) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedTabBody(index: index, child: Text('Aba $index')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
      for (var previous = 0; previous < index; previous++) {
        expect(find.text('Aba $previous'), findsNothing);
      }
    }
    await tester.pumpAndSettle();
    expect(find.text('Aba 3'), findsOneWidget);
  });

  testWidgets('Toque repetido abre apenas uma página', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                AppRoutes.push(
                  context,
                  '/detalhe',
                  (_) => const Scaffold(body: Text('Destino')),
                );
                AppRoutes.push(
                  context,
                  '/detalhe',
                  (_) => const Scaffold(body: Text('Destino')),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('Grupo abre opções e seleciona o roteiro correto', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrailResultsMap(
            trails: [trail('a', -23.4), trail('b', -23.4)],
            tileProvider: _Tiles(),
            onSelected: (trail) => selected = trail.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('2 roteiros nesta região'));
    await tester.pumpAndSettle();
    expect(find.text('Roteiro a'), findsOneWidget);
    await tester.tap(find.text('Roteiro b'));
    await tester.pumpAndSettle();
    expect(selected, 'b');
  });

  for (final recovery in [false, true]) {
    testWidgets(
      'Link ${recovery ? 'de recuperação' : 'de confirmação'} inicia sessão uma vez',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await SessionService.instance.clear();
        var calls = 0;
        String? role;
        final gateway = AuthGateway(
          api: ApiClient(
            client: MockClient((request) async {
              calls++;
              expect(request.headers['Authorization'], isNull);
              final body = jsonDecode(request.body);
              expect(body['iniciar_sessao'], isTrue);
              if (recovery) expect(body['nova_senha'], 'nova1234');
              return http.Response(
                jsonEncode({
                  'id': 'u1',
                  'email': 'p@example.test',
                  'tipo': 'usuario',
                  'token': 'jwt-da-api',
                }),
                200,
              );
            }),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: AccountLinkScreen(
              email: 'p@example.test',
              token: 'a' * 43,
              recoverPassword: recovery,
              gateway: gateway,
              onAuthenticated: (value) async => role = value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(calls, 0);
        if (recovery) {
          await tester.enterText(find.byType(TextField).at(0), 'nova1234');
          await tester.enterText(find.byType(TextField).at(1), 'nova1234');
        }
        final button = find.text(
          recovery ? 'Salvar senha e entrar' : 'Confirmar e entrar',
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(role, 'usuario');
        expect(SessionService.instance.token, 'jwt-da-api');
        expect(calls, 1);
        await tester.tap(find.text('Continuar para a Home'));
        await tester.pumpAndSettle();
        expect(calls, 1);
      },
    );
  }
}
