import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/models/trail_accessibility.dart';
import 'package:rotafacil/widgets/trail_accessibility_section.dart';

void main() {
  test('Legado não presume recursos; contrato preserva sim, não e nulo', () {
    final legacy = Trail.fromJson({'acessivel': true});
    expect(
      legacy.accessibility.display('mobilidade_reduzida'),
      'Não informado',
    );
    expect(legacy.accessibility.matches(['mobilidade_reduzida']), false);
    final trail = Trail.fromJson({
      'acessibilidade': {
        'apoio_visual': true,
        'apoio_auditivo': false,
        'banheiro_acessivel': null,
        'idade_minima': 0,
        'adaptacoes': 'Apoio',
      },
    });
    final value = Trail.fromJson(trail.toJson()).accessibility;
    expect(value.display('apoio_visual'), 'Sim');
    expect(value.display('apoio_auditivo'), 'Não');
    expect(value.display('banheiro_acessivel'), 'Não informado');
    expect(value.display('idade_minima'), '0');
    expect(value.matches(['apoio_visual']), true);
    expect(value.matches(['apoio_visual', 'apoio_auditivo']), false);
    expect(value.matches([]), true);
  });
  testWidgets(
    'Detalhes apresentam todas as condições sem inventar informação',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrailAccessibilitySection(
                value: TrailAccessibility({
                  'apoio_visual': true,
                  'apoio_auditivo': false,
                  'idade_minima': 12,
                }),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Apoio para deficiência visual: Sim'), findsOneWidget);
      expect(find.text('Apoio para deficiência auditiva: Não'), findsOneWidget);
      expect(find.text('Banheiro acessível: Não informado'), findsOneWidget);
      expect(find.text('Idade mínima (anos): 12'), findsOneWidget);
    },
  );
  testWidgets(
    'Editor permite declarar e remover informação, sem confundir ausência com não',
    (tester) async {
      TrailAccessibility result = const TrailAccessibility();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrailAccessibilityEditor(
                initial: result,
                onChanged: (value) => result = value,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sim').last);
      await tester.pumpAndSettle();
      expect(result.answer('mobilidade_reduzida'), true);
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Não informado').last);
      await tester.pumpAndSettle();
      expect(result.answer('mobilidade_reduzida'), null);
    },
  );
}
