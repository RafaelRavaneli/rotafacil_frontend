import 'package:rotafacil/pages/agency/remote_guides_screen.dart';
import 'package:rotafacil/state/app_store.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/community_api.dart';
import 'package:rotafacil/services/session_service.dart';
import 'package:rotafacil/pages/common/remote_conversations_screen.dart';
import 'package:rotafacil/utils/role_utils.dart';
import 'package:rotafacil/utils/document_validator.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.instance.save(
      selectedRole: 'usuario',
      userEmail: 't@example.test',
      id: 't',
    );
  });
  test('Aliases compartilham normalização e validação de cadastro', () {
    for (final role in ['Agência', 'agencia', 'agency']) {
      expect(normalizeRoleKey(role), 'agencia');
      expect(DocumentValidator.labelForRole(role), 'CNPJ');
      expect(
        DocumentValidator.isValidForRole(role, '11.222.333/0001-81'),
        isTrue,
      );
      expect(DocumentValidator.isValidForRole(role, '52998224725'), isFalse);
    }
    for (final role in ['Guia', 'guide']) {
      expect(normalizeRoleKey(role), 'guia');
      expect(DocumentValidator.isValidForRole(role, '52998224725'), isTrue);
      expect(DocumentValidator.isValidForRole(role, '11111111111'), isFalse);
    }
    for (final role in ['usuario', 'turista', 'tourist']) {
      expect(normalizeRoleKey(role), 'turista');
    }
  });
  testWidgets('Mensagem com erro preserva texto e permite novo envio', (
    tester,
  ) async {
    var posts = 0;
    final messages = <Map<String, dynamic>>[];
    final api = CommunityApi(
      api: ApiClient(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            if (posts == 1) {
              return http.Response('{"erro":"Falha temporaria"}', 503);
            }
            final body = jsonDecode(request.body) as Map;
            expect(body.keys, ['texto']);
            messages.add({
              'id_autor': 't',
              'nome_autor': 'Turista',
              'texto': body['texto'],
            });
            return http.Response.bytes(
              utf8.encode(jsonEncode(messages.last)),
              200,
            );
          }
          return http.Response.bytes(utf8.encode(jsonEncode(messages)), 200);
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RemoteMessagesScreen(
          path: '/api/conversas/c/mensagens',
          title: 'Guia',
          api: api,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Olá guia');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Olá guia',
    );
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(posts, 2);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Olá guia'), findsOneWidget);
  });
  testWidgets('Turista inicia conversa selecionando ID do catálogo', (
    tester,
  ) async {
    final api = CommunityApi(
      api: ApiClient(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            expect(jsonDecode(request.body), {'id_guia': 'g'});
            return http.Response(
              '{"id":"c","nomes":{"g":"Guia Ana","t":"Turista"}}',
              200,
            );
          }
          return http.Response(
            request.url.path == '/api/guias'
                ? '[{"id":"g","nome":"Guia Ana"}]'
                : '[]',
            200,
          );
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: RemoteConversationsScreen(api: api)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova conversa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guia Ana'));
    await tester.pumpAndSettle();
    expect(find.text('Envie a primeira mensagem.'), findsOneWidget);
  });

  testWidgets('Atualizar convites traz aceite remoto ao seletor de guias', (
    tester,
  ) async {
    await SessionService.instance.save(
      selectedRole: 'agencia',
      userEmail: 'a@example.test',
      id: 'a',
    );
    var accepted = false;
    final api = CommunityApi(
      api: ApiClient(
        client: MockClient((request) async {
          final result = request.url.path == '/api/guias'
              ? <Map<String, dynamic>>[]
              : [
                  {
                    'id': 'invite',
                    'id_guia': 'g',
                    'nome_guia': 'Guia Ana',
                    'status': accepted ? 'aceito' : 'pendente',
                  },
                ];
          return http.Response(jsonEncode(result), 200);
        }),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: RemoteGuidesScreen(api: api)));
    await tester.pumpAndSettle();
    expect(AppStore.instance.agencyGuides, isEmpty);
    accepted = true;
    await tester.tap(find.byTooltip('Atualizar'));
    await tester.pumpAndSettle();
    expect(AppStore.instance.agencyGuides.single.id, 'g');
    expect(AppStore.instance.agencyGuides.single.name, 'Guia Ana');
    AppStore.instance.agencyGuides.clear();
  });
}
