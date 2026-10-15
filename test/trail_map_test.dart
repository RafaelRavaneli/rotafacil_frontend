import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/pages/tourist/trail_search_screen.dart';
import 'package:rotafacil/pages/tourist/trail_details_screen.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/widgets/trail_results_map.dart';

class _StaticTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('assets/images/auth_background.png');
}

class _DeniedLocation extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;
  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;
}

void main() {
  Trail trail(double? latitude, double? longitude) => Trail.fromJson({
    'id': 't1',
    'nome': 'Trilha',
    'latitude': latitude,
    'longitude': longitude,
  });

  test('Mapa preserva coordenadas recebidas e aceita zero', () {
    final position = trailMapPosition(trail(-23.5, -51.2))!;
    expect(position.latitude, -23.5);
    expect(position.longitude, -51.2);
    expect(trailMapPosition(trail(0, 0)), isNotNull);
  });

  test('Mapa rejeita coordenadas ausentes, fora do limite ou não finitas', () {
    for (final value in [
      trail(null, -51),
      trail(-23, null),
      trail(91, 0),
      trail(0, -181),
      trail(double.nan, 0),
      trail(0, double.infinity),
    ]) {
      expect(trailMapPosition(value), isNull);
    }
  });

  testWidgets('Mapa sem coordenadas explica como consultar os resultados', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrailResultsMap(
            trails: [trail(null, null)],
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(
      find.textContaining('Consulte a lista de resultados'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  test(
    'Distância decimal é preservada e ausência não inventa zero quilômetros',
    () {
      expect(Trail.fromJson({'distancia_km': '15,5'}).distanceLabel, '15,5 km');
      expect(Trail.fromJson({'distancia_km': 15}).distanceLabel, '15 km');
      for (final value in [null, '', -1, 0, 'NaN', 'Infinity']) {
        expect(
          Trail.fromJson({
            'distancia_km': value,
            'descricao': 'Percurso de 15 km',
          }).distanceLabel,
          'Distância não informada',
        );
      }
      expect(
        Trail.fromJson({'nome_guia': 'Mateus Guia'}).responsibleName,
        'Mateus Guia',
      );
      expect(Trail.fromJson({}).responsibleName, 'Responsável não informado');
    },
  );

  testWidgets('Marcador abre trilha correta sem duplicar cartão ao retornar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore.instance;
    await store.initialize();
    final old = List<Trail>.from(store.trails);
    addTearDown(() {
      store.trails
        ..clear()
        ..addAll(old);
    });
    store.trails
      ..clear()
      ..addAll([
        Trail.fromJson({
          'id': 'mapa',
          'nome': 'Trilha mapa',
          'cidade': 'Maringá',
          'latitude': -23.4,
          'longitude': -51.9,
          'nome_guia': 'Mateus Guia',
        }),
        Trail.fromJson({
          'id': 'sem',
          'nome': 'Sem coordenadas',
          'cidade': 'Maringá',
        }),
      ]);
    await tester.pumpWidget(
      MaterialApp(home: TrailSearchScreen(tileProvider: _StaticTiles())),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Abrir trilha: Sem coordenadas'), findsNothing);
    final marker = find.byTooltip('Abrir trilha: Trilha mapa');
    await tester.ensureVisible(marker);
    await tester.pumpAndSettle();
    await tester.tap(marker);
    await tester.pumpAndSettle();
    expect(find.byType(TrailDetailsScreen), findsOneWidget);
    expect(
      tester
          .widget<TrailDetailsScreen>(find.byType(TrailDetailsScreen))
          .trail
          .id,
      'mapa',
    );
    final detailsContext = tester.element(find.byType(TrailDetailsScreen));
    Navigator.of(detailsContext).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Trilha mapa'));
    expect(find.text('Trilha mapa'), findsOneWidget);
    expect(find.text('Sem coordenadas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filtro de acessibilidade mantém somente percursos informados', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore.instance;
    await store.initialize();
    final old = List<Trail>.from(store.trails);
    store.trails
      ..clear()
      ..addAll([
        Trail.fromJson({
          'id': 'acessivel',
          'nome': 'Percurso acessível',
          'ativo': true,
          'acessivel': true,
        }),
        Trail.fromJson({
          'id': 'comum',
          'nome': 'Percurso comum',
          'ativo': true,
        }),
      ]);
    addTearDown(() {
      store.trails
        ..clear()
        ..addAll(old);
    });

    await tester.pumpWidget(const MaterialApp(home: TrailSearchScreen()));
    expect(find.text('2 resultado(s)'), findsOneWidget);
    await tester.tap(find.text('Somente trilhas acessíveis'));
    await tester.pump();
    expect(find.text('1 resultado(s)'), findsOneWidget);
  });

  testWidgets(
    'Localização negada orienta usuário sem erro técnico e mantém busca',
    (tester) async {
      final original = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = _DeniedLocation();
      addTearDown(() => GeolocatorPlatform.instance = original);
      final store = AppStore.instance;
      final old = List<Trail>.from(store.trails);
      store.trails.clear();
      addTearDown(() {
        store.trails
          ..clear()
          ..addAll(old);
      });
      await tester.pumpWidget(const MaterialApp(home: TrailSearchScreen()));
      await tester.tap(find.text('Buscar perto de mim'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Permita o acesso à localização'),
        findsOneWidget,
      );
      expect(find.textContaining('Bad state'), findsNothing);
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Buscar perto de mim'),
            )
            .value,
        isFalse,
      );
      await tester.enterText(find.byType(TextField).first, 'Maringá');
      await tester.pump();
      expect(
        find.text('Nenhuma trilha encontrada com esses filtros.'),
        findsOneWidget,
      );
    },
  );
}
