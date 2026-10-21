import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/services/session_service.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/backend_repository.dart';
import 'package:rotafacil/pages/admin/admin_console_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.instance.save(
      authToken: 'token-local',
      selectedRole: 'admin',
      userEmail: 'adm@test.local',
      id: 'adm',
    );
  });
  test(
    'Conta bloqueada encerra sessão e preserva motivo de encerramento',
    () async {
      final api = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'erro': 'Conta bloqueada',
              'codigo': 'CONTA_BLOQUEADA',
            }),
            403,
          ),
        ),
      );
      await expectLater(
        api.get('/api/admin/contas'),
        throwsA(isA<ApiException>()),
      );
      expect(SessionService.instance.token, isNull);
      expect(
        SessionService.instance.consumeEndReason(),
        SessionEndReason.blocked,
      );
    },
  );
  test(
    'Contrato administrativo envia filtro e motivo sem dados de privilégio do cliente',
    () async {
      final paths = <String>[];
      final repo = BackendRepository(
        api: ApiClient(
          client: MockClient((request) async {
            paths.add(request.url.path);
            if (request.method == 'GET') {
              expect(request.url.queryParameters, {
                'estado': 'bloqueadas',
                'tipo': 'guia',
                'q': 'Ana',
              });
              return http.Response('[]', 200);
            }
            expect(jsonDecode(request.body), {
              'acao': 'bloquear',
              'motivo': 'Conferência',
            });
            return http.Response('{}', 200);
          }),
        ),
      );
      await repo.adminRows('contas', {
        'estado': 'bloqueadas',
        'tipo': 'guia',
        'q': 'Ana',
      });
      await repo.adminAction('contas', 'g', 'bloquear', 'Conferência');
      expect(paths, ['/api/admin/contas', '/api/admin/contas/g/acao']);
    },
  );
  testWidgets('Perfil comum não carrega painel administrativo', (tester) async {
    await SessionService.instance.save(
      authToken: 'token-local',
      selectedRole: 'Guia',
      userEmail: 'g@test.local',
      id: 'g',
    );
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AdminConsoleScreen(
          load: (section, filters) async {
            calls++;
            return [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Acesso administrativo necessário.'), findsOneWidget);
  });
  testWidgets(
    'Bloqueio exige motivo e atualiza lista sem erro ao fechar diálogo',
    (tester) async {
      var active = true;
      final actions = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AdminConsoleScreen(
            load: (section, filters) async => [
              {
                'id': 'g',
                'nome': 'Guia de teste',
                'email': 'g@test.local',
                'tipo': 'guia',
                'ativo': active,
                'verificado': false,
              },
            ],
            apply: (section, id, action, reason) async {
              actions.add('$section/$id/$action/$reason');
              active = false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Verificação profissional'), findsOneWidget);
      expect(find.byTooltip('Moderar avaliações'), findsOneWidget);
      await tester.ensureVisible(find.text('Bloquear'));
      await tester.tap(find.text('Bloquear'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'ab');
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      expect(actions, isEmpty);
      await tester.enterText(find.byType(TextField).last, 'Conferência');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(actions, ['contas/g/bloquear/Conferência']);
      expect(find.text('Conta bloqueada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Troca de seção carrega filtros próprios e histórico administrativo',
    (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AdminConsoleScreen(
            load: (section, filters) async {
              calls.add(
                '$section/${filters['tipo'] ?? ''}/${filters['estado'] ?? ''}',
              );
              return section == 'historico'
                  ? [
                      {
                        'tipo': 'roteiro',
                        'acao': 'suspender',
                        'id_alvo': 't',
                        'motivo': 'Análise',
                        'resultado': 'aplicada',
                        'criado_em': '2026-10-21T10:00:00Z',
                      },
                    ]
                  : [];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Roteiros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(calls, [
        'contas/todos/todos',
        'roteiros//todos',
        'historico/todos/',
      ]);
      expect(find.text('Referência: t'), findsOneWidget);
      expect(find.text('Análise'), findsOneWidget);
    },
  );
}
