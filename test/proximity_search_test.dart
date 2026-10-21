import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/location_service.dart';
import 'package:rotafacil/services/trail_search_service.dart';
import 'package:rotafacil/pages/tourist/trail_search_screen.dart';
import 'package:rotafacil/pages/tourist/tourist_home_tab.dart';

void main() {
  testWidgets('Resposta antiga não substitui busca atual ao retornar à janela', (
    tester,
  ) async {
    final old = Completer<http.Response>();
    var calls = 0;
    final service = TrailSearchService(
      api: ApiClient(
        client: MockClient((request) async {
          calls++;
          if (calls == 1) return old.future;
          return http.Response(
            '{"itens":[],"total":0,"proxima_pagina":null}',
            200,
          );
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: TrailSearchScreen(searchService: service)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(calls, 2);
    old.complete(
      http.Response(
        '{"itens":[{"id":"velho","nome":"Resultado antigo"}],"total":1,"proxima_pagina":null}',
        200,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 resultado(s)'), findsOneWidget);
    expect(find.text('Resultado antigo'), findsNothing);
  }, skip: !AppConfig.useBackend);

  test(
    'Consulta remota preserva coordenada zero, filtros, página e distância do servidor',
    () async {
      final service = TrailSearchService(
        api: ApiClient(
          client: MockClient((request) async {
            expect(request.url.path, '/api/trilhas/busca');
            expect(request.url.queryParameters, containsPair('latitude', '0'));
            expect(request.url.queryParameters, containsPair('raio_km', '100'));
            expect(request.url.queryParameters, containsPair('pagina', '2'));
            expect(
              request.url.queryParameters,
              containsPair('modalidade', 'Rapel'),
            );
            return http.Response(
              jsonEncode({
                'itens': [
                  {
                    'id': 'remoto',
                    'nome': 'Roteiro remoto',
                    'distancia_usuario_km': 12.345678,
                  },
                ],
                'total': 31,
                'proxima_pagina': null,
              }),
              200,
            );
          }),
        ),
      );
      final result = await service.search({
        'latitude': '0',
        'longitude': '0',
        'raio_km': '100',
        'modalidade': 'Rapel',
      }, page: 2);
      expect(result.items.single.distanceKm, 12.345678);
      expect(result.total, 31);
      expect(result.nextPage, isNull);
    },
  );

  testWidgets(
    'Busca trata falha remota e permite tentar novamente sem usar catálogo local',
    (tester) async {
      var requests = 0;
      final service = TrailSearchService(
        api: ApiClient(
          client: MockClient((request) async {
            requests++;
            if (requests == 1) return http.Response('{"erro":"Offline"}', 503);
            return http.Response(
              '{"itens":[],"total":0,"proxima_pagina":null}',
              200,
            );
          }),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: TrailSearchScreen(searchService: service)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final retry = find.text('Tentar novamente');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(requests, 2);
      expect(find.text('0 resultado(s)'), findsOneWidget);
      expect(
        find.text('Nenhum roteiro encontrado com esses filtros.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    skip: !AppConfig.useBackend,
  );

  testWidgets('Home solicita raio 100 no servidor; GPS negado não consulta API', (
    tester,
  ) async {
    var requests = 0;
    final service = TrailSearchService(
      api: ApiClient(
        client: MockClient((request) async {
          requests++;
          expect(request.url.queryParameters['raio_km'], '100');
          expect(request.url.queryParameters['latitude'], '0.0');
          return http.Response(
            '{"itens":[{"id":"proximo","nome":"Roteiro proximo","distancia_usuario_km":12.345}],"total":1,"proxima_pagina":null}',
            200,
          );
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TouristHomeTab(
            searchService: service,
            locate: () async => UserCoordinates(latitude: 0, longitude: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 1);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text('12,3 km de você'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TouristHomeTab(
            searchService: service,
            locate: () async => throw StateError('Permita a localização.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('Permita a localização.'), findsWidgets);
    expect(tester.takeException(), isNull);
  }, skip: !AppConfig.useBackend);
}
