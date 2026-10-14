import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/pages/agency/guides_screen.dart';
import 'package:rotafacil/pages/agency/remote_guides_screen.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/community_api.dart';
import 'package:rotafacil/services/session_service.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/theme/app_theme.dart';

http.Response response(dynamic body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

Widget app(Widget screen) => MaterialApp(theme: AppTheme.light, home: screen);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.instance.save(
      selectedRole: 'agencia',
      userEmail: 'agencia@example.test',
      id: 'a',
    );
    AppStore.instance.agencyGuides.clear();
  });

  testWidgets(
    'Agência confirma envio, mantém contrato e bloqueia envio duplicado',
    (tester) async {
      var posts = 0;
      final pending = Completer<http.Response>();
      final invites = <Map<String, dynamic>>[];
      final api = CommunityApi(
        api: ApiClient(
          client: MockClient((request) async {
            if (request.method == 'POST') {
              posts++;
              expect(request.url.path, '/api/convites-guias');
              expect(jsonDecode(request.body), {'id_guia': 'g'});
              return pending.future;
            }
            return response(
              request.url.path == '/api/guias'
                  ? [
                      {
                        'id': 'g',
                        'nome': 'Guia Ana',
                        'cidade': 'Maringá',
                        'estado': 'PR',
                      },
                    ]
                  : invites,
            );
          }),
        ),
      );
      await tester.pumpWidget(app(RemoteGuidesScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Convidar'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Convidar'));
      await tester.pumpAndSettle();
      expect(posts, 0);
      await tester.tap(find.text('Enviar convite'));
      await tester.pumpAndSettle();
      expect(posts, 1);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Enviando...'),
            )
            .onPressed,
        isNull,
      );
      invites.add({
        'id': 'i',
        'id_guia': 'g',
        'nome_guia': 'Guia Ana',
        'status': 'pendente',
      });
      pending.complete(response({'id': 'i'}));
      await tester.pumpAndSettle();
      expect(find.text('Convidar'), findsNothing);
      expect(find.text('Convite pendente'), findsWidgets);
    },
  );

  for (final choice in [
    ('Aceitar', 'Confirmar aceite', 'aceito', 'Convite aceito'),
    ('Recusar', 'Confirmar recusa', 'recusado', 'Convite recusado'),
  ]) {
    testWidgets('Guia responde ${choice.$3} usando convite correto', (
      tester,
    ) async {
      await SessionService.instance.save(
        selectedRole: 'guia',
        userEmail: 'guia@example.test',
        id: 'g',
      );
      var status = 'pendente';
      var writes = 0;
      final api = CommunityApi(
        api: ApiClient(
          client: MockClient((request) async {
            if (request.method == 'PUT') {
              writes++;
              expect(request.url.path, '/api/convites-guias/i');
              expect(jsonDecode(request.body), {'status': choice.$3});
              status = choice.$3;
              return response({});
            }
            expect(request.url.path, '/api/convites-guias');
            return response([
              {'id': 'i', 'nome_agencia': 'Agência de teste', 'status': status},
            ]);
          }),
        ),
      );
      await tester.pumpWidget(app(RemoteGuidesScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice.$1));
      await tester.pumpAndSettle();
      expect(writes, 0);
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      await tester.tap(find.text(choice.$1));
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice.$2));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.text(choice.$4), findsOneWidget);
      expect(find.text('Aceitar'), findsNothing);
      expect(find.text('Recusar'), findsNothing);
    });
  }

  testWidgets('Falha de envio mantém opção para tentar novamente', (
    tester,
  ) async {
    var posts = 0;
    final api = CommunityApi(
      api: ApiClient(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            return response({'erro': 'Falha temporária'}, 503);
          }
          return response(
            request.url.path == '/api/guias'
                ? [
                    {'id': 'g', 'nome': 'Ana'},
                  ]
                : [],
          );
        }),
      ),
    );
    await tester.pumpWidget(app(RemoteGuidesScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Convidar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Convidar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar convite'));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.textContaining('Falha temporária'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Convidar'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Erro de consulta permite recarregar e exibe estados vazios', (
    tester,
  ) async {
    var fail = true;
    final api = CommunityApi(
      api: ApiClient(
        client: MockClient(
          (request) async =>
              fail ? response({'erro': 'Sem conexão'}, 503) : response([]),
        ),
      ),
    );
    await tester.pumpWidget(app(RemoteGuidesScreen(api: api)));
    expect(find.text('Carregando guias e convites...'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum convite.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nenhum guia cadastrado.'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nenhum guia cadastrado.'), findsOneWidget);
  });

  for (final status in ['pendente', 'aceito', 'recusado']) {
    testWidgets('Convite $status não oferece reenvio nem revogação', (
      tester,
    ) async {
      final api = CommunityApi(
        api: ApiClient(
          client: MockClient(
            (request) async => response(
              request.url.path == '/api/guias'
                  ? [
                      {'id': 'g', 'nome': 'Ana'},
                    ]
                  : [
                      {
                        'id': 'i',
                        'id_guia': 'g',
                        'nome_guia': 'Ana',
                        'status': status,
                      },
                    ],
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(RemoteGuidesScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(find.text('Convidar'), findsNothing);
      expect(find.text('Revogar'), findsNothing);
      expect(AppStore.instance.agencyGuides.length, status == 'aceito' ? 1 : 0);
    });
  }

  for (final role in ['agencia', 'guia']) {
    for (final width in [320.0, 1024.0]) {
      testWidgets('Guias e convites de $role cabem em $width pixels', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await SessionService.instance.save(
          selectedRole: role,
          userEmail: 'teste@example.test',
          id: 'u',
        );
        final api = CommunityApi(
          api: ApiClient(
            client: MockClient(
              (request) async => response(
                request.url.path == '/api/guias'
                    ? [
                        {
                          'id': 'g',
                          'nome': 'Guia com nome longo para testar a tela',
                          'verificado': true,
                        },
                      ]
                    : [
                        {
                          'id': 'i',
                          'id_guia': 'g',
                          'nome_guia': 'Nome do guia para teste',
                          'nome_agencia': 'Agência com nome longo para teste',
                          'status': 'pendente',
                        },
                      ],
              ),
            ),
          ),
        );
        await tester.pumpWidget(app(RemoteGuidesScreen(api: api)));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Modo local identifica demonstração e valida registro antes de salvar',
    (tester) async {
      await AppStore.instance.initialize();
      AppStore.instance.agencyGuides.clear();
      await tester.pumpWidget(app(const GuidesScreen()));
      expect(find.text('Demonstração local'), findsOneWidget);
      await tester.tap(find.text('Adicionar guia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar guia'));
      await tester.pumpAndSettle();
      expect(find.text('Informe o nome.'), findsOneWidget);
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Guia local');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'local@example.test',
      );
      await tester.tap(find.text('Salvar guia'));
      await tester.pumpAndSettle();
      expect(AppStore.instance.agencyGuides.single.name, 'Guia local');
      expect(find.text('Guia local'), findsOneWidget);
    },
    skip: AppConfig.useBackend,
  );
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
