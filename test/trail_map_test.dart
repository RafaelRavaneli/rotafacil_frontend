import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/widgets/trail_results_map.dart';

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
}
