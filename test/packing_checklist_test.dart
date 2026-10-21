import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/models/local_booking.dart';
import 'package:rotafacil/models/packing_checklist.dart';
import 'package:rotafacil/services/backend_repository.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/session_service.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/widgets/personal_checklist_card.dart';

void main() {
  final trail = Trail.fromJson({
    'id': 't1',
    'nome': 'Roteiro',
    'itens_obrigatorios': ['Água', 'Lanterna'],
    'itens_recomendados': [' água ', 'Boné'],
  });
  LocalBooking booking(String id) => LocalBooking(
    id: id,
    trailId: 't1',
    trailName: 'Roteiro',
    personName: 'Pessoa',
    date: '2026-12-01',
    status: 'confirmado',
    roleView: 'turista',
  );

  test('Itens obrigatórios são preservados e não duplicam recomendados', () {
    final reloaded = Trail.fromJson(trail.toJson());
    expect(reloaded.requiredItems, ['Água', 'Lanterna']);
    final checklist = PackingChecklist.fromTrail(reloaded);
    expect(checklist.items.map((item) => item.name), [
      'Água',
      'Lanterna',
      'Boné',
    ]);
    expect(checklist.requiredRemaining, 2);
    expect(PackingChecklist.itemId(' água '), PackingChecklist.itemId('Água'));
    expect(
      Trail.fromJson({
        'itens_recomendados': ['Água'],
      }).requiredItems,
      isEmpty,
    );
  });

  test(
    'Marcações locais sobrevivem à recarga e ficam separadas por usuário e reserva',
    () async {
      SharedPreferences.setMockInitialValues({});
      await AppStore.instance.initialize();
      await SessionService.instance.save(
        selectedRole: 'usuario',
        userEmail: 'p@example.test',
        id: 'u1',
      );
      final id = PackingChecklist.itemId('Água');
      await AppStore.instance.updatePackingItem(booking('b1'), trail, id, true);
      expect(
        (await AppStore.instance.packingChecklistFor(
          booking('b1'),
          trail,
        )).prepared,
        1,
      );
      expect(
        (await AppStore.instance.packingChecklistFor(
          booking('b2'),
          trail,
        )).prepared,
        0,
      );
      await SessionService.instance.save(
        selectedRole: 'usuario',
        userEmail: 'outra@example.test',
        id: 'u2',
      );
      expect(
        (await AppStore.instance.packingChecklistFor(
          booking('b1'),
          trail,
        )).prepared,
        0,
      );
      await SessionService.instance.save(
        selectedRole: 'usuario',
        userEmail: 'p@example.test',
        id: 'u1',
      );
      await AppStore.instance.updatePackingItem(
        booking('b1'),
        trail,
        id,
        false,
      );
      expect(
        (await AppStore.instance.packingChecklistFor(
          booking('b1'),
          trail,
        )).prepared,
        0,
      );
    },
    skip: AppConfig.useBackend,
  );

  test(
    'Contrato usa somente reserva e item, sem enviar identidade do turista',
    () async {
      final calls = <http.Request>[];
      final repository = BackendRepository(
        api: ApiClient(
          client: MockClient((request) async {
            calls.add(request);
            return http.Response(
              jsonEncode({
                'editavel': true,
                'itens': [
                  {
                    'id': 'item1',
                    'nome': 'Água',
                    'obrigatorio': true,
                    'marcado': request.method == 'PATCH',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
      expect((await repository.packingChecklist('b1')).prepared, 0);
      expect(
        (await repository.updatePackingItem('b1', 'item1', true)).prepared,
        1,
      );
      expect(calls.last.url.path, '/api/agendamentos/b1/checklist');
      expect(jsonDecode(calls.last.body), {
        'id_item': 'item1',
        'marcado': true,
      });
    },
  );

  testWidgets('Falha ao salvar não marca item e permite nova tentativa', (
    tester,
  ) async {
    var saves = 0;
    final id = PackingChecklist.itemId('Água');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalChecklistCard(
              booking: booking('b1'),
              trail: trail,
              load: () async =>
                  PackingChecklist.fromTrail(trail, editable: true),
              save: (item, checked) async {
                saves++;
                if (saves == 1) throw Exception('offline');
                return PackingChecklist.fromTrail(
                  trail,
                  checked: {id: checked},
                  editable: true,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final checkbox = find.byType(CheckboxListTile).first;
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);
    expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);
    expect(find.textContaining('1 de 3 itens preparados'), findsOneWidget);
  });

  testWidgets(
    'Falha de leitura mantém lista visível e não oferece marcação falsa',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonalChecklistCard(
                booking: booking('b1'),
                trail: trail,
                load: () async => throw Exception('offline'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Água'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.textContaining('Não foi possível carregar'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    },
  );
}
