import 'dart:convert';
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.instance.clear();
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
      );
      expect(result.userId, 'u1');
      expect(jsonDecode(requests[0].body)['documento'], '52998224725');
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
        }),
        create: true,
      );
    },
  );
}
