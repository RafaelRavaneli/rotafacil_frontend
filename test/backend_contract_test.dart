import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/models/user_role.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/auth_gateway.dart';
import 'package:rotafacil/services/backend_repository.dart';
import 'package:rotafacil/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Previsão usa dia selecionado sem retornar previsão de outra saída',
    () async {
      final repository = BackendRepository(
        api: ApiClient(
          client: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'previsao_do_dia_da_trilha': {
                  'data': '2026-10-21',
                  'condicao': 'Chuva',
                },
                'previsao_completa': [
                  {'data': '2026-10-21', 'condicao': 'Chuva'},
                  {'data': '2026-10-25', 'condicao': 'Céu limpo'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        ),
      );
      expect(
        (await repository.weather(
          't1',
          date: DateTime(2026, 10, 25),
        ))?.condition,
        'Céu limpo',
      );
      expect(
        await repository.weather('t1', date: DateTime(2026, 12, 1)),
        isNull,
      );
    },
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.instance.clear();
  });

  test('Finalização preserva id antigo e envia apenas o dia', () async {
    final repository = BackendRepository(
      api: ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/agendamentos/finalizar-saida');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['id_data'], 'legacy-t1');
          expect(body['data_agendada'], '2026-10-24');
          return http.Response('{}', 200);
        }),
      ),
    );
    await repository.finishDeparture(
      trailId: 't1',
      departureId: 'legacy-t1',
      date: '2026-10-24T04:30:00.000',
    );
  });

  test('HTTP decodifica UTF-8 e preserva erros de autorização', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/ok') {
          return http.Response.bytes(utf8.encode('{"nome":"São José"}'), 200);
        }
        return http.Response('{"erro":"Token expirado"}', 401);
      }),
    );
    expect((await api.get('/ok'))['nome'], 'São José');
    await expectLater(
      api.get('/erro'),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 401),
      ),
    );
  });

  test('HTTP 401 encerra sessão ativa com mensagem legível', () async {
    await SessionService.instance.save(
      authToken: 'jwt-expirado',
      selectedRole: 'usuario',
      userEmail: 'teste@example.test',
      id: 'u1',
    );
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response('{"erro":"Token expirado"}', 401),
      ),
    );

    await expectLater(
      api.get('/protegido'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 401)
            .having(
              (error) => error.message,
              'mensagem',
              'Sua sessão expirou. Entre novamente.',
            ),
      ),
    );
    expect(SessionService.instance.token, isNull);
    expect(
      SessionService.instance.consumeEndReason(),
      SessionEndReason.expired,
    );
  });

  test(
    'Logout em outra aba é detectado pelo armazenamento compartilhado',
    () async {
      await SessionService.instance.save(
        authToken: 'jwt',
        selectedRole: 'usuario',
        userEmail: 'teste@example.test',
        id: 'u1',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      expect(await SessionService.instance.synchronizeFromStorage(), isTrue);
      expect(SessionService.instance.role, isNull);
      expect(
        SessionService.instance.consumeEndReason(),
        SessionEndReason.externalLogout,
      );
    },
  );

  test('Upload informa o tipo MIME da imagem ao backend', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        expect(request, isA<http.Request>());
        final body = utf8.decode(request.bodyBytes, allowMalformed: true);
        expect(body.toLowerCase(), contains('content-type: image/png'));
        return http.Response('{"url":"https://example.test/foto.png"}', 200);
      }),
    );
    final result = await api.uploadMultipart(
      '/api/uploads/imagem',
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'foto.png',
    );
    expect(result['url'], 'https://example.test/foto.png');
  });

  test(
    'Trilha inativa não aparece como ativa e aceita coordenadas numéricas em texto',
    () {
      final trail = Trail.fromJson({
        'id': 't1',
        'nome': 'Trilha',
        'ativo': false,
        'preco': 42,
        'latitude': '-23.5',
        'longitude': -51.2,
      });
      expect(trail.status, TrailStatus.inactive);
      expect(trail.price, 42);
      expect(trail.latitude, -23.5);
      expect(BackendRepository.apiDate('25/09/2026 • 08:00'), '2026-09-25');
    },
  );

  test('Detalhe usa todas as atividades cadastradas no roteiro', () {
    final trail = Trail.fromJson({
      'id': 't1',
      'nome': 'Cachoeira',
      'modalidade': 'Trilha',
      'atividades': ['Aquatrekking', 'Rapel'],
    });
    expect(trail.effectiveActivities, ['Aquatrekking', 'Rapel']);
  });

  test(
    'Carga remota combina perfil, trilhas, favoritos e agendamentos',
    () async {
      await SessionService.instance.save(
        authToken: 'jwt',
        selectedRole: 'usuario',
        userEmail: 'teste@example.test',
        id: 'u1',
      );
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer jwt');
          final Object data = switch (request.url.path) {
            '/api/usuarios/u1' => {
              'id': 'u1',
              'nome': 'Ana',
              'email': 'teste@example.test',
              'tipo': 'usuario',
              'cidade': 'Maringá',
            },
            '/api/trilhas/' => [
              {'id': 't1', 'nome': 'Trilha real', 'preco': 25},
            ],
            '/api/favoritos/' => [
              {'id': 't1'},
            ],
            '/api/agendamentos/usuario/u1' => [
              {
                'id': 'b1',
                'id_trilha': 't1',
                'id_usuario': 'u1',
                'status': 'agendado',
                'valor_pago': 25,
                'data_agendada': '2026-09-25',
              },
            ],
            _ => throw StateError('Rota inesperada: ${request.url}'),
          };
          return http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
        }),
      );
      final snapshot = await BackendRepository(api: api).load();
      expect(snapshot.user.name, 'Ana');
      expect(snapshot.user.city, 'Maringá');
      expect(snapshot.favorites, {'t1'});
      expect(snapshot.bookings.single.trailName, 'Trilha real');
      expect(snapshot.bookings.single.status, 'Confirmado');
    },
  );

  test(
    'Falha de rede não retorna dados demonstrativos como dados da API',
    () async {
      await SessionService.instance.save(
        authToken: 'jwt',
        selectedRole: 'usuario',
        userEmail: 'teste@example.test',
        id: 'u1',
      );
      final repository = BackendRepository(
        api: ApiClient(
          client: MockClient((_) async {
            throw http.ClientException('offline');
          }),
        ),
      );
      await expectLater(
        repository.load(),
        throwsA(isA<http.ClientException>()),
      );
    },
  );

  test(
    'Cadastro de guia envia documento e redefinição envia token e nova_senha',
    () async {
      final requests = <http.Request>[];
      final gateway = AuthGateway(
        api: ApiClient(
          client: MockClient((request) async {
            requests.add(request);
            return http.Response('{"id":"u1"}', 201);
          }),
        ),
      );
      final result = await gateway.register(
        role: UserRole.guide,
        name: 'Guia',
        email: 'guia@example.test',
        password: 'senha123',
        document: '529.982.247-25',
        cadasturNumber: '12.345.678/0001-90',
      );
      expect(result.userId, 'u1');
      expect(jsonDecode(requests[0].body)['documento'], '52998224725');
      expect(jsonDecode(requests[0].body)['cadastur_numero'], '12345678000190');
      expect(jsonDecode(requests[0].body).containsKey('cpf'), false);
      await gateway.requestPasswordReset('guia@example.test');
      expect(requests[1].url.path, '/api/auth/senha/solicitar');
      await gateway.resetPassword(
        email: 'guia@example.test',
        newPassword: 'nova123',
        token: 'codigo',
      );
      expect(requests[2].url.path, '/api/auth/senha/redefinir');
      expect(jsonDecode(requests[2].body), {
        'token': 'codigo',
        'nova_senha': 'nova123',
      });
      await gateway.changePassword(
        role: 'Guia',
        currentPassword: 'senha123',
        newPassword: 'nova456',
      );
      expect(requests[3].method, 'PUT');
      expect(requests[3].url.path, '/api/auth/senha');
      expect(jsonDecode(requests[3].body), {
        'senha_atual': 'senha123',
        'nova_senha': 'nova456',
      });
    },
    skip: !const bool.fromEnvironment('USE_BACKEND'),
  );

  test(
    'Criação de trilha usa nomes de campo e data do contrato Flask',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/trilhas/');
          final body = jsonDecode(request.body);
          expect(body['nome'], 'Caminho');
          expect(body['id_guia'], 'u1');
          expect(body['data_atividade'], '2026-09-25');
          expect(body['preco'], 35);
          expect(body['acessivel'], true);
          expect(body['itens_recomendados'], ['Água', 'Boné']);
          expect(body['trajeto'], [
            {'latitude': -23.4, 'longitude': -51.9},
          ]);
          expect(body['capacidade'], 8);
          expect(body['horario_inicio'], '08:00');
          expect(body['horario_fim'], '12:00');
          expect(body.containsKey('latitude'), false);
          return http.Response('{"id":"t1"}', 201);
        }),
      );
      await BackendRepository(api: api).saveTrail(
        Trail.fromJson({
          'id': 't1',
          'nome': 'Caminho',
          'id_guia': 'u1',
          'preco': 35,
          'date': '25/09/2026',
          'acessivel': true,
          'itens_recomendados': ['Água', 'Boné'],
          'trajeto': [
            {'latitude': -23.4, 'longitude': -51.9},
          ],
          'capacidade': 8,
          'horario_inicio': '08:00',
          'horario_fim': '12:00',
        }),
        create: true,
      );
    },
  );

  test('Exclusão de conta usa o usuário autenticado e método DELETE', () async {
    final requests = <http.Request>[];
    final repository = BackendRepository(
      api: ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          expect(request.headers['Authorization'], 'Bearer jwt');
          return http.Response.bytes(
            utf8.encode('{"mensagem":"Conta excluída"}'),
            200,
          );
        }),
      ),
    );
    await SessionService.instance.save(
      authToken: 'jwt',
      selectedRole: 'usuario',
      userEmail: 'ana@example.test',
      id: 'u 1',
    );

    await repository.deleteAccount(SessionService.instance.userId!);

    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, '/api/usuarios/u%201');
  });

  test('Alteração de tipo usa rota específica e documento validado', () async {
    late http.Request captured;
    final repository = BackendRepository(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response.bytes(
            utf8.encode('{"mensagem":"Tipo alterado"}'),
            200,
          );
        }),
      ),
    );

    await repository.changeAccountType(
      userId: 'u1',
      type: 'guia',
      document: '52998224725',
    );

    expect(captured.method, 'PUT');
    expect(captured.url.path, '/api/usuarios/u1/tipo');
    expect(jsonDecode(captured.body), {
      'tipo': 'guia',
      'documento': '52998224725',
    });
  });

  test(
    'Documentos profissionais usam acesso autenticado e análise separada',
    () async {
      await SessionService.instance.save(
        authToken: 'jwt',
        selectedRole: 'admin',
        userEmail: 'admin@example.test',
        id: 'admin1',
      );
      final requests = <http.Request>[];
      final repository = BackendRepository(
        api: ApiClient(
          client: MockClient((request) async {
            requests.add(request);
            expect(request.headers['Authorization'], 'Bearer jwt');
            if (request.url.path == '/api/documentos-profissionais/') {
              return http.Response.bytes(
                utf8.encode(
                  '[{"id":"d1","id_usuario":"g1","status":"pendente",'
                  '"tipo_documento":"cadastur","nome_arquivo":"doc.png"}]',
                ),
                200,
              );
            }
            if (request.url.path.endsWith('/arquivo')) {
              return http.Response.bytes([1, 2, 3], 200);
            }
            return http.Response.bytes(
              utf8.encode('{"mensagem":"Documento aprovado"}'),
              200,
            );
          }),
        ),
      );

      final documents = await repository.professionalDocuments(
        status: 'pendente',
      );
      expect(documents.single.id, 'd1');
      expect(requests[0].url.queryParameters['status'], 'pendente');
      expect(await repository.professionalDocumentBytes('d1'), [1, 2, 3]);
      await repository.reviewProfessionalDocument(id: 'd1', status: 'aprovado');
      expect(requests[2].method, 'PUT');
      expect(requests[2].url.path, '/api/documentos-profissionais/d1/analise');
    },
  );

  test(
    'Central e preferências de notificações usam contratos remotos',
    () async {
      final requests = <http.Request>[];
      final repository = BackendRepository(
        api: ApiClient(
          client: MockClient((request) async {
            requests.add(request);
            final Object data = switch (request.url.path) {
              '/api/notificacoes/' => [
                {
                  'id': 'n1',
                  'titulo': 'Reserva',
                  'corpo': 'Confirmada',
                  'lida': false,
                  'criado_em': '2026-10-15T10:00:00Z',
                },
              ],
              '/api/notificacoes/preferencias' =>
                request.method == 'GET'
                    ? {'push': true, 'agendamentos': false, 'marketing': true}
                    : {'push': false},
              _ => {'mensagem': 'ok'},
            };
            return http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
          }),
        ),
      );

      final notifications = await repository.notifications();
      expect(notifications.single.title, 'Reserva');
      expect(notifications.single.read, false);
      expect(await repository.notificationPreferences(), {
        'push': true,
        'agendamentos': false,
        'marketing': true,
      });
      await repository.markNotificationRead('n1');
      await repository.markAllNotificationsRead();
      await repository.updateNotificationPreferences({'push': false});
      expect(requests[2].url.path, '/api/notificacoes/n1/lida');
      expect(requests[3].url.path, '/api/notificacoes/lidas');
      expect(jsonDecode(requests[4].body), {'push': false});
    },
  );

  test('Perfil público do guia usa somente o contrato sanitizado', () async {
    final repository = BackendRepository(
      api: ApiClient(
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              '{"id":"g1","nome":"Ana","cidade":"Maringá",'
              '"estado":"PR","verificado":true,'
              '"descricao_profissional":"Condutora de ecoturismo",'
              '"especialidades":["Trekking","Cachoeiras"]}',
            ),
            200,
          ),
        ),
      ),
    );

    final guide = await repository.publicGuide('g1');
    expect(guide.name, 'Ana');
    expect(guide.verified, true);
    expect(guide.bio, 'Condutora de ecoturismo');
    expect(guide.specialties, ['Trekking', 'Cachoeiras']);
  });

  test('Login aceita papel administrativo retornado pelo servidor', () async {
    final gateway = AuthGateway(
      api: ApiClient(
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              '{"token":"cabecalho.YWRtaW4.assinatura",'
              '"id":"a1","tipo":"admin"}',
            ),
            200,
          ),
        ),
      ),
    );
    final result = await gateway.login(
      email: 'admin@example.test',
      password: 'senha123',
    );
    expect(result?.role, 'admin');
  }, skip: !const bool.fromEnvironment('USE_BACKEND'));

  for (final role in ['guia', 'agencia']) {
    test('Agenda de $role usa somente ID autenticado no carregamento', () async {
      await SessionService.instance.save(
        authToken: 'jwt',
        selectedRole: role,
        userEmail: 'guia@example.test',
        id: 'g1',
      );
      final paths = <String>[];
      final repository = BackendRepository(
        api: ApiClient(
          client: MockClient((request) async {
            paths.add(request.url.path);
            expect(request.headers['Authorization'], 'Bearer jwt');
            if (request.url.path.startsWith('/api/agendamentos/guia/') &&
                request.url.path != '/api/agendamentos/guia/g1') {
              return http.Response(
                '{"erro":"Acesso negado. Você só pode acessar sua própria agenda."}',
                403,
              );
            }
            final Object data = switch (request.url.path) {
              '/api/usuarios/g1' => {
                'id': 'g1',
                'nome': 'Guia',
                'tipo': role,
                'email': 'guia@example.test',
              },
              '/api/trilhas/' => [
                {'id': 't1', 'nome': 'Trilha'},
              ],
              '/api/agendamentos/guia/g1' || '/api/agendamentos/agencia/g1' => [
                {
                  'id': 'b1',
                  'id_trilha': 't1',
                  'id_usuario': 't1',
                  'status': 'agendado',
                },
                {
                  'id': 'b2',
                  'id_trilha': 't1',
                  'id_usuario': 't2',
                  'status': 'agendado',
                  'id_guia': 'guia@example.test',
                },
              ],
              '/api/agendamentos/dashboard/g1' => {
                'total_agendamentos': 2,
                'por_status': {'agendado': 2, 'cancelado': 0},
                'valor_declarado_ativo': 50.5,
              },
              '/api/favoritos/' ||
              '/api/agendamentos/usuario/g1' ||
              '/api/convites-guias' => [],
              _ => throw StateError('Rota inesperada: ${request.url}'),
            };
            return http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
          }),
        ),
      );
      final snapshot = await repository.load();
      expect(snapshot.bookings.map((b) => b.id).toSet(), {'b1', 'b2'});
      expect(snapshot.dashboard?.active, 2);
      expect(snapshot.dashboard?.declaredValue, 50.5);
      final expectedAgenda = '/api/agendamentos/$role/g1';
      expect(paths.where((p) => p == expectedAgenda), [expectedAgenda]);
      if (role == 'agencia') {
        expect(
          paths.where((p) => p.startsWith('/api/agendamentos/guia/')),
          isEmpty,
        );
      }
    });
  }
  test('Agenda mantém bloqueio real de autorização pelo ID', () async {
    await SessionService.instance.save(
      authToken: 'jwt',
      selectedRole: 'guia',
      userEmail: 'guia@example.test',
      id: 'g1',
    );
    final repository = BackendRepository(
      api: ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/api/agendamentos/guia/g1') {
            return http.Response('{"erro":"Agenda negada"}', 403);
          }
          return http.Response(
            request.url.path.startsWith('/api/usuarios/')
                ? '{"id":"g1","nome":"Guia"}'
                : '[]',
            200,
          );
        }),
      ),
    );
    await expectLater(
      repository.load(),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
    );
  });
}
