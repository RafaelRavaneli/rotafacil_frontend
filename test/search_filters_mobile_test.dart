import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/pages/tourist/trail_search_screen.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/trail_search_service.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> configure(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final store = AppStore.instance;
    await store.initialize();
    final previous = List<Trail>.from(store.trails);
    store.trails
      ..clear()
      ..addAll([
        Trail.fromJson({
          'id': 'iniciante',
          'nome': 'Cachoeira tranquila',
          'dificuldade': 'Iniciante',
          'ativo': true,
        }),
        Trail.fromJson({
          'id': 'avancado',
          'nome': 'Percurso avançado',
          'dificuldade': 'Avançado',
          'ativo': true,
        }),
      ]);
    addTearDown(() {
      store.trails
        ..clear()
        ..addAll(previous);
    });
  }

  testWidgets('Mobile mostra resultados e reabre filtros preservando seleção', (
    tester,
  ) async {
    await configure(tester, const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(home: TrailSearchScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('2 resultado(s)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('search-filters-toggle')));
    await tester.pumpAndSettle();
    final difficulty = find.byKey(const ValueKey('Todas'));
    await tester.ensureVisible(difficulty);
    await tester.tap(difficulty);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avançado').last);
    await tester.pumpAndSettle();

    final results = find.byKey(const ValueKey('search-show-results'));
    await tester.ensureVisible(results);
    await tester.tap(results);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('1 resultado(s)'), findsOneWidget);
    expect(find.text('Cachoeira tranquila'), findsNothing);
    expect(find.text('Avançado'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar filtros'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('Avançado')),
          )
          .initialValue,
      'Avançado',
    );
    final clear = find.text('Limpar filtros');
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.ensureVisible(results);
    await tester.tap(results);
    await tester.pumpAndSettle();
    expect(find.text('2 resultado(s)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: AppConfig.useBackend);

  testWidgets('Largura intermediária mantém filtros visíveis', (tester) async {
    await configure(tester, const Size(800, 900));
    await tester.pumpWidget(const MaterialApp(home: TrailSearchScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsWidgets);
    expect(find.byKey(const ValueKey('search-filters-toggle')), findsNothing);
    expect(find.byKey(const ValueKey('search-show-results')), findsNothing);
    expect(tester.takeException(), isNull);
  }, skip: AppConfig.useBackend);

  testWidgets('Desktop mantém resultados à esquerda e mapa à direita', (
    tester,
  ) async {
    await configure(tester, const Size(1440, 900));
    await tester.pumpWidget(const MaterialApp(home: TrailSearchScreen()));
    await tester.pumpAndSettle();
    final results = find.byKey(const ValueKey('search-results-pane'));
    final map = find.byKey(const ValueKey('search-map-pane'));
    expect(tester.getRect(results).right, lessThan(tester.getRect(map).left));
    expect(tester.getRect(results).top, tester.getRect(map).top);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('search-filters-toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsWidgets);
    expect(results, findsOneWidget);
    expect(map, findsOneWidget);
    await tester.tap(find.byTooltip('Recolher filtros'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Ocultar mapa'));
    await tester.pumpAndSettle();
    expect(map, findsNothing);
    expect(results, findsOneWidget);
    await tester.tap(find.text('Mostrar mapa'));
    await tester.pumpAndSettle();
    expect(map, findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: AppConfig.useBackend);

  testWidgets(
    'Resultado remoto recolhe filtros uma vez sem fechar edição em atualização',
    (tester) async {
      await configure(tester, const Size(390, 844));
      final queries = <Map<String, String>>[];
      final service = TrailSearchService(
        api: ApiClient(
          client: MockClient((request) async {
            queries.add(request.url.queryParameters);
            return http.Response(
              jsonEncode({
                'itens': [
                  {
                    'id': 'remoto',
                    'nome': 'Roteiro encontrado',
                    'dificuldade': 'Avançado',
                  },
                ],
                'total': 1,
                'proxima_pagina': null,
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: TrailSearchScreen(searchService: service)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('1 resultado(s)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('search-filters-toggle')));
      await tester.pumpAndSettle();
      final difficulty = find.byKey(const ValueKey('Todas'));
      await tester.ensureVisible(difficulty);
      await tester.tap(difficulty);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avançado').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(queries.last['dificuldade'], 'Avançado');
      expect(find.byType(TextField), findsWidgets);

      final results = find.byKey(const ValueKey('search-show-results'));
      await tester.ensureVisible(results);
      await tester.tap(results);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(queries.last['dificuldade'], 'Avançado');
      expect(find.text('1 resultado(s)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: !AppConfig.useBackend,
  );
}
