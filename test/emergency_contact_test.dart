import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/models/app_user.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/backend_repository.dart';
import 'package:rotafacil/services/session_service.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/pages/common/settings/personal_data_screen.dart';
import 'package:rotafacil/widgets/organizer_emergency_card.dart';

void main() {
  test(
    'Perfil antigo não concede consentimento; contrato preserva relação e autorização',
    () {
      expect(
        AppUser.fromJson({'nome': 'Pessoa'}).emergencyContactConsent,
        false,
      );
      final user = AppUser.fromJson({
        'contato_emergencia_nome': 'Contato',
        'contato_emergencia_telefone': '44999990000',
        'contato_emergencia_relacao': 'Irmã',
        'contato_emergencia_consentimento': true,
      });
      final copy = AppUser.fromJson(user.toJson());
      expect(copy.emergencyContactConsent, true);
      expect(copy.emergencyContactRelation, 'Irmã');
    },
  );
  test(
    'Consulta envia reserva e autenticação, propaga acesso negado',
    () async {
      SharedPreferences.setMockInitialValues({});
      await SessionService.instance.save(
        authToken: 'token-local',
        selectedRole: 'Guia',
        userEmail: 'g@example.test',
        id: 'g',
      );
      var deny = false;
      final repository = BackendRepository(
        api: ApiClient(
          client: MockClient((request) async {
            expect(request.url.path, '/api/usuarios/u/contato-emergencia');
            expect(request.url.queryParameters, {'id_agendamento': 'b/1'});
            expect(request.headers['Authorization'], 'Bearer token-local');
            if (deny) {
              return http.Response('{"erro":"Contato indisponível"}', 403);
            }
            return http.Response(
              jsonEncode({
                'contato_emergencia_nome': 'Contato',
                'contato_emergencia_telefone': '44999990000',
                'contato_emergencia_relacao': 'Irmã',
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
      expect(
        (await repository.emergencyContact('u', bookingId: 'b/1')).relation,
        'Irmã',
      );
      deny = true;
      await expectLater(
        repository.emergencyContact('u', bookingId: 'b/1'),
        throwsA(isA<ApiException>()),
      );
    },
  );
  testWidgets(
    'Organizador apresenta ausência explícita e mantém telefone/instruções após recarga',
    (tester) async {
      final trail = Trail.fromJson({
        'emergencia_organizador_telefone': '44999990000',
        'emergencia_instrucoes': 'Ligue para a equipe.',
      });
      final copy = Trail.fromJson(trail.toJson());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OrganizerEmergencyCard(trail: copy)),
        ),
      );
      expect(find.text('Ligue para a equipe.'), findsOneWidget);
      expect(find.text('Ligar para o organizador'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrganizerEmergencyCard(trail: Trail.fromJson({})),
          ),
        ),
      );
      expect(find.text('Telefone não informado'), findsOneWidget);
      expect(find.text('Instruções não informadas'), findsOneWidget);
      expect(find.text('Ligar para o organizador'), findsNothing);
    },
  );
  testWidgets(
    'Remover contato limpa dados e retira consentimento antes de salvar',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppStore.instance.initialize();
      final user = AppStore.instance.tourist;
      user.emergencyContactName = 'Contato';
      user.emergencyContactPhone = '44999990000';
      user.emergencyContactRelation = 'Irmã';
      user.emergencyContactConsent = true;
      await tester.pumpWidget(
        MaterialApp(
          home: const PersonalDataScreen(role: 'Turista'),
          routes: {'/perfil': (_) => const Scaffold(body: Text('Perfil'))},
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Remover contato ao salvar'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Remover contato ao salvar'));
      await tester.tap(find.text('Remover contato ao salvar'));
      await tester.pump();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        false,
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Salvar alterações'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();
      expect(user.emergencyContactConsent, false);
      expect(user.emergencyContactPhone, '');
      expect(user.emergencyContactName, '');
      expect(user.emergencyContactRelation, '');
    },
    skip: AppConfig.useBackend,
  );
}
