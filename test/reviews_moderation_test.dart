import 'package:rotafacil/pages/admin/review_moderation_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rotafacil/models/trail_experience.dart';
import 'package:rotafacil/services/backend_repository.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/widgets/reviews_panel.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/models/guide.dart';
import 'package:rotafacil/pages/tourist/guide_profile_screen.dart';

void main() {
  test(
    'Modelo preserva zero, notas profissionais, data e edição autorizada',
    () {
      final value = TrailReview.fromJson({
        'id': 'b',
        'nota_roteiro': 0,
        'nota_guia': 4,
        'nota_agencia': 5,
        'createdAt': '2026-10-20T10:00:00Z',
        'editavel': true,
      });
      expect(value.rating, 0);
      expect(value.guideRating, 4);
      expect(value.agencyRating, 5);
      expect(value.editable, true);
      expect(
        TrailReview.fromJson({'status_moderacao': 'oculta'}).editable,
        false,
      );
      expect(value.createdAt, '2026-10-20T10:00:00Z');
    },
  );
  test(
    'Contrato identifica reserva, restringe campos de edição e envia motivo de moderação',
    () async {
      final seen = <String>[];
      final repository = BackendRepository(
        api: ApiClient(
          client: MockClient((request) async {
            seen.add('${request.method} ${request.url.path}');
            if (request.method == 'PATCH') {
              expect(jsonDecode(request.body), {
                'nota': 0,
                'nota_guia': 4,
                'nota_agencia': 5,
                'comentario': 'Editado',
              });
            }
            if (request.url.path.endsWith('/denunciar')) {
              expect(jsonDecode(request.body), {
                'motivo': 'spam',
                'descricao': 'Repetição',
              });
            }
            if (request.url.path.endsWith('/moderar')) {
              expect(jsonDecode(request.body), {
                'acao': 'ocultar',
                'motivo': 'Revisado',
              });
            }
            return http.Response(request.method == 'GET' ? '[]' : '{}', 200);
          }),
        ),
      );
      await repository.editReview('b', {
        'nota': 0,
        'nota_guia': 4,
        'nota_agencia': 5,
        'comentario': 'Editado',
      });
      await repository.reportReview('b', 'spam', 'Repetição');
      await repository.moderateReview('b', 'ocultar', 'Revisado');
      await repository.professionalReviews('a');
      expect(seen, [
        'PATCH /api/avaliacoes/b',
        'POST /api/avaliacoes/b/denunciar',
        'POST /api/avaliacoes/b/moderar',
        'GET /api/avaliacoes/profissional/a',
      ]);
    },
  );
  testWidgets(
    'Recarregar substitui avaliações ocultadas e mostra data/autor e nota zero',
    (tester) async {
      var hidden = false;
      Future<List<TrailReview>> load() async => hidden
          ? []
          : [
              TrailReview.fromJson({
                'id': 'b',
                'nome_usuario': 'Participante',
                'nota_roteiro': 0,
                'comentario': 'Experiência',
                'createdAt': '2026-10-20T10:00:00Z',
              }),
            ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewsPanel(id: 't', load: load),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Participante · 0/5'), findsOneWidget);
      expect(find.text('Experiência'), findsOneWidget);
      expect(find.text('Denunciar'), findsOneWidget);
      hidden = true;
      await tester.tap(find.byTooltip('Atualizar avaliações'));
      await tester.pumpAndSettle();
      expect(find.text('Experiência'), findsNothing);
      expect(find.text('Ainda não há avaliações publicadas.'), findsOneWidget);
    },
  );
  testWidgets('Cartões de avaliação ocupam toda a largura do painel', (
    tester,
  ) async {
    Future<List<TrailReview>> load() async => [
      TrailReview.fromJson({
        'id': 'curta',
        'nome_usuario': 'Ana',
        'nota_roteiro': 5,
        'comentario': 'Ótima.',
      }),
      TrailReview.fromJson({
        'id': 'longa',
        'nome_usuario': 'Bruno',
        'nota_roteiro': 4,
        'comentario': 'Trilha linda, mas a descida cansa. Bom ir preparado.',
      }),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewsPanel(id: 't', load: load),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cards = tester.widgetList<Card>(find.byType(Card)).toList();
    expect(cards, hasLength(2));
    final widths = find
        .byType(Card)
        .evaluate()
        .map((element) => tester.getSize(find.byWidget(element.widget)).width)
        .toSet();
    expect(widths, hasLength(1));
    Finder surface(Finder card) =>
        find.descendant(of: card, matching: find.byType(Material)).first;
    final gap =
        tester.getTopLeft(surface(find.byType(Card).last)).dy -
        tester.getBottomLeft(surface(find.byType(Card).first)).dy;
    expect(gap, greaterThanOrEqualTo(12));
  });
  testWidgets('Perfil do guia abre as avaliações em tela própria', (
    tester,
  ) async {
    const guide = GuideProfile(
      id: 'g1',
      name: 'Carla Mendes',
      rating: 5,
      reviews: 2,
      imageUrl: '',
      bio: 'Guia de montanha.',
      specialties: ['Trekking'],
      experienceYears: 5,
      completedTrails: 10,
      totalKm: 100,
      city: 'Curitiba',
      state: 'PR',
    );
    await tester.pumpWidget(
      const MaterialApp(home: GuideProfileScreen(guide: guide)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReviewsPanel), findsNothing);
    await tester.tap(find.text('Ver avaliações'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideReviewsScreen), findsOneWidget);
    expect(find.text('Avaliações de Carla Mendes'), findsOneWidget);
    expect(find.byType(ReviewsPanel), findsOneWidget);
  }, skip: AppConfig.useBackend);
  testWidgets(
    'Falha de rede permite repetir consulta sem exibir média demonstrativa',
    (tester) async {
      var fail = true;
      Future<List<TrailReview>> load() async {
        if (fail) throw Exception('offline');
        return [];
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewsPanel(id: 't', load: load),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Tentar novamente'), findsOneWidget);
      fail = false;
      await tester.tap(find.textContaining('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Ainda não há avaliações publicadas.'), findsOneWidget);
    },
  );
  testWidgets(
    'Admin recarrega e justifica moderação antes de retirar avaliação da fila',
    (tester) async {
      var visible = true;
      var loads = 0;
      final actions = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewModerationScreen(
            load: (status) async {
              loads++;
              return visible
                  ? [
                      {
                        'id': 'b',
                        'nome_usuario': 'Pessoa',
                        'nota_roteiro': 0,
                        'comentario': 'Revisar',
                        'status_moderacao': 'publicada',
                        'denuncias': [],
                        'historico': [],
                      },
                    ]
                  : [];
            },
            apply: (id, action, reason) async {
              actions.add('$id/$action/$reason');
              visible = false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Atualizar'));
      await tester.pumpAndSettle();
      expect(loads, 2);
      await tester.tap(find.text('Ocultar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Dados pessoais');
      await tester.tap(find.text('Confirmar decisão'));
      await tester.pumpAndSettle();
      expect(actions, ['b/ocultar/Dados pessoais']);
      expect(find.text('Nenhuma avaliação neste filtro.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Cancelar denúncia fecha formulário sem reutilizar controlador descartado',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewsPanel(
              id: 't',
              load: () async => [
                const TrailReview(
                  id: 'b',
                  userName: 'Pessoa',
                  rating: 0,
                  comment: 'Experiência',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Denunciar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Descrição');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Denunciar avaliação'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
