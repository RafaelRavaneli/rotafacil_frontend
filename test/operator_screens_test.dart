import 'package:rotafacil/pages/guide/guide_shell.dart';
import 'package:rotafacil/pages/agency/agency_shell.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/models/local_booking.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/pages/common/booking_details_screen.dart';
import 'package:rotafacil/pages/common/bookings_screen.dart';
import 'package:rotafacil/pages/common/operator_dashboard.dart';
import 'package:rotafacil/pages/common/trails_management_screen.dart';
import 'package:rotafacil/pages/common/trail_participants_screen.dart';
import 'package:rotafacil/pages/management/trail_form_screen.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/theme/app_theme.dart';
import 'package:rotafacil/pages/tourist/trail_details_screen.dart';
import 'package:rotafacil/widgets/trail_weather_card.dart';

LocalBooking reservation({String status = 'Confirmado'}) => LocalBooking(
  id: 'r1',
  trailId: 't1',
  trailName: 'Trilha de demonstração',
  personName: 'Pessoa de teste',
  date: '25/10/2026',
  status: status,
  roleView: 'turista',
  valuePaid: 120,
);

void main() {
  final store = AppStore.instance;
  const previewDirectory = String.fromEnvironment('FRONTEND_PREVIEW_DIR');
  const fontDirectory = String.fromEnvironment('FRONTEND_FONT_DIR');
  setUpAll(() async {
    if (previewDirectory.isNotEmpty && fontDirectory.isNotEmpty) {
      final text = FontLoader('Roboto');
      for (final file in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
        text.addFont(
          File(
            '$fontDirectory/$file',
          ).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      }
      await text.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File(
          '$fontDirectory/materialicons-regular.otf',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
      await icons.load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.initialize();
    store.bookingNotifications = false;
    store.bookings
      ..clear()
      ..add(reservation());
    final departureStart = DateTime.now().add(const Duration(days: 5));
    final departureEnd = departureStart.add(const Duration(hours: 6));
    store.trails
      ..clear()
      ..add(
        Trail.fromJson({
          'id': 't1',
          'nome': 'Trilha de demonstração',
          'cidade': 'Maringá',
          'estado': 'PR',
          'preco': 120,
          'imagem_url': '',
          'datas': [
            {
              'id': 'd1',
              'data_hora_inicio': departureStart.toIso8601String(),
              'data_hora_fim': departureEnd.toIso8601String(),
            },
          ],
        }),
      );
  });

  Widget app(Widget page) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: previewDirectory.isEmpty
        ? AppTheme.light
        : AppTheme.light.copyWith(
            textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
            filledButtonTheme: FilledButtonThemeData(
              style: AppTheme.light.filledButtonTheme.style!.merge(
                FilledButton.styleFrom(
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
    home: Scaffold(body: page),
  );

  testWidgets('Lista abre detalhe da reserva selecionada', (tester) async {
    await tester.pumpWidget(app(const BookingsScreen(role: 'turista')));
    await tester.tap(find.text('Ver detalhes da reserva'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingDetailsScreen), findsOneWidget);
    expect(find.text('r1'), findsOneWidget);
    expect(find.text('Pessoa de teste'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('não comprova pagamento'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('não comprova pagamento'), findsOneWidget);
    expect(find.text('Fazer check-in'), findsNothing);
    expect(find.text('Fazer check-out'), findsNothing);
  });

  testWidgets('Reserva usa horário e previsão da saída reservada', (
    tester,
  ) async {
    final trail = Trail.fromJson({
      ...store.trails.single.toJson(),
      'recommendedItems': ['Água', 'Calçado fechado'],
      'latitude': -23.4,
      'longitude': -51.9,
      'departures': [
        {
          'id': 'd1',
          'data_hora_inicio': '2099-10-10T08:00',
          'data_hora_fim': '2099-10-10T16:00',
        },
        {
          'id': 'd2',
          'data_hora_inicio': '2099-11-10T06:30',
          'data_hora_fim': '2099-11-11T15:00',
        },
      ],
    });
    store.trails
      ..clear()
      ..add(trail);
    store.bookings
      ..clear()
      ..add(
        LocalBooking(
          id: 'r1',
          trailId: 't1',
          trailName: trail.name,
          personName: 'Ana',
          date: '2099-11-10',
          status: 'Confirmado',
          roleView: 'turista',
          departureId: 'd2',
        ),
      );
    await tester.pumpWidget(app(const BookingDetailsScreen(bookingId: 'r1')));
    await tester.scrollUntilVisible(
      find.text('O que levar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('10/11/2099 às 06:30'), findsOneWidget);
    expect(find.text('11/11/2099 às 15:00'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TrailWeatherCard),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Água'), findsOneWidget);
    expect(find.text('Abrir rota no Google Maps'), findsOneWidget);
    expect(
      tester.widget<TrailWeatherCard>(find.byType(TrailWeatherCard)).date,
      DateTime(2099, 11, 10, 6, 30),
    );
  });

  testWidgets('Seletor de previsão troca data sem alterar reserva', (
    tester,
  ) async {
    final trail = Trail.fromJson({
      ...store.trails.single.toJson(),
      'departures': [
        {
          'id': 'd1',
          'data_hora_inicio': '2099-10-10T08:00',
          'data_hora_fim': '2099-10-10T16:00',
        },
        {
          'id': 'd2',
          'data_hora_inicio': '2099-11-10T08:00',
          'data_hora_fim': '2099-11-10T16:00',
        },
      ],
    });
    await tester.pumpWidget(app(TrailDetailsScreen(trail: trail)));
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<DateTime>),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byType(DropdownButtonFormField<DateTime>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<DateTime>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10/11/2099 às 08:00').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TrailWeatherCard>(find.byType(TrailWeatherCard)).date,
      DateTime(2099, 11, 10, 8),
    );
    expect(store.bookings.single.id, 'r1');
  });

  test('Check-in e check-out ficam bloqueados na camada de estado', () async {
    expect(
      () => store.checkInBooking(store.bookings.single),
      throwsA(isA<StateError>()),
    );
    store.bookings.single.status = 'Em andamento';
    expect(
      () => store.checkOutBooking(store.bookings.single),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('Cancelamento exige confirmação e atualiza o detalhe', (
    tester,
  ) async {
    await tester.pumpWidget(app(const BookingDetailsScreen(bookingId: 'r1')));
    await tester.scrollUntilVisible(
      find.text('Cancelar reserva'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Cancelar reserva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter reserva'));
    await tester.pumpAndSettle();
    expect(store.bookings.single.status, 'Confirmado');
    await tester.tap(find.text('Cancelar reserva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar cancelamento'));
    await tester.pumpAndSettle();
    expect(store.bookings.single.status, 'Cancelado');
    expect(find.text('Cancelar reserva'), findsNothing);
    expect(find.text('Cancelado'), findsOneWidget);
  }, skip: AppConfig.useBackend);

  testWidgets('Reserva ausente oferece retorno sem exibir dados antigos', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const BookingDetailsScreen(bookingId: 'ausente')),
    );
    expect(
      find.textContaining('Esta reserva não está disponível'),
      findsOneWidget,
    );
    expect(find.text('Cancelar reserva'), findsNothing);
  });

  testWidgets(
    'Detalhe usa registro atualizado e preserva reserva sem roteiro',
    (tester) async {
      store.trails.clear();
      await tester.pumpWidget(app(BookingDetailsScreen(bookingId: 'r1')));
      await tester.scrollUntilVisible(
        find.textContaining('Os dados atuais do roteiro não estão disponíveis'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.textContaining('Os dados atuais do roteiro não estão disponíveis'),
        findsOneWidget,
      );
      store.bookings
        ..clear()
        ..add(reservation(status: 'Cancelado'));
      await tester.pumpWidget(app(BookingDetailsScreen(bookingId: 'r1')));
      await tester.scrollUntilVisible(
        find.text('Cancelado'),
        -200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Cancelado'), findsOneWidget);
      expect(find.text('Cancelar reserva'), findsNothing);
    },
  );

  testWidgets('Gestão de roteiros inicia mostrando somente ativos', (
    tester,
  ) async {
    store.trails
      ..clear()
      ..addAll([
        Trail.fromJson({
          'id': 'ativo',
          'nome': 'Roteiro ativo',
          'cidade': 'Maringá',
          'estado': 'PR',
          'preco': 120,
          'imagem_url': '',
          'ativo': true,
        }),
        Trail.fromJson({
          'id': 'inativo',
          'nome': 'Roteiro desativado',
          'cidade': 'Maringá',
          'estado': 'PR',
          'preco': 120,
          'imagem_url': '',
          'ativo': false,
        }),
      ]);

    await tester.pumpWidget(app(const TrailsManagementScreen(isAgency: false)));
    await tester.pumpAndSettle();

    expect(find.text('Ativos'), findsOneWidget);
    expect(find.text('Roteiro ativo'), findsOneWidget);
    expect(find.text('Roteiro desativado'), findsNothing);
  }, skip: AppConfig.useBackend);

  testWidgets('Inscritos podem ser filtrados pela data do roteiro', (
    tester,
  ) async {
    final trail = Trail.fromJson({
      'id': 't1',
      'nome': 'Roteiro com datas',
      'cidade': 'Maringá',
      'estado': 'PR',
      'datas': [
        {
          'id': 'd1',
          'data_hora_inicio': '2099-10-10T08:00',
          'data_hora_fim': '2099-10-10T16:00',
        },
        {
          'id': 'd2',
          'data_hora_inicio': '2099-11-10T08:00',
          'data_hora_fim': '2099-11-10T16:00',
        },
      ],
    });
    store.bookings
      ..clear()
      ..addAll([
        LocalBooking(
          id: 'b1',
          trailId: 't1',
          trailName: trail.name,
          personName: 'Ana',
          date: '2099-10-10',
          status: 'Confirmado',
          roleView: 'guia',
          departureId: 'd1',
        ),
        LocalBooking(
          id: 'b2',
          trailId: 't1',
          trailName: trail.name,
          personName: 'Bruno',
          date: '2099-11-10',
          status: 'Confirmado',
          roleView: 'guia',
          departureId: 'd2',
        ),
      ]);

    await tester.pumpWidget(app(TrailParticipantsScreen(trail: trail)));
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
    await tester.tap(find.text('Todas as datas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10/10/2099 às 08:00').last);
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bruno'), findsNothing);
  }, skip: AppConfig.useBackend);

  testWidgets('Guia confirma solicitação pendente nos inscritos', (
    tester,
  ) async {
    store.bookings
      ..clear()
      ..add(reservation(status: 'Pendente'));
    await tester.pumpWidget(
      app(TrailParticipantsScreen(trail: store.trails.single)),
    );
    expect(find.textContaining('Aguardando confirmação'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.text('Recusar'), findsOneWidget);
    expect(find.text('Entrar em contato'), findsOneWidget);
    expect(find.text('Detalhes da reserva'), findsNothing);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar').last);
    await tester.pumpAndSettle();
    expect(store.bookings.single.status, BookingStatus.confirmed);
    expect(find.text('Detalhes da reserva'), findsOneWidget);
  }, skip: AppConfig.useBackend);

  testWidgets('Finalização da saída conclui somente a data selecionada', (
    tester,
  ) async {
    final trail = Trail.fromJson({
      'id': 't1',
      'nome': 'Roteiro com datas',
      'cidade': 'Maringá',
      'estado': 'PR',
      'datas': [
        {
          'id': 'd1',
          'data_hora_inicio': '2026-10-10T08:00',
          'data_hora_fim': '2026-10-10T16:00',
        },
        {
          'id': 'd2',
          'data_hora_inicio': '2026-11-10T08:00',
          'data_hora_fim': '2026-11-10T16:00',
        },
      ],
    });
    store.bookings
      ..clear()
      ..addAll([
        LocalBooking(
          id: 'b1',
          trailId: 't1',
          trailName: trail.name,
          personName: 'Ana',
          date: '2026-10-10',
          status: 'Confirmado',
          roleView: 'guia',
          departureId: 'd1',
        ),
        LocalBooking(
          id: 'b2',
          trailId: 't1',
          trailName: trail.name,
          personName: 'Bruno',
          date: '2026-11-10',
          status: 'Confirmado',
          roleView: 'guia',
          departureId: 'd2',
        ),
      ]);
    await tester.pumpWidget(app(TrailParticipantsScreen(trail: trail)));
    await tester.tap(find.text('Todas as datas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10/10/2026 às 08:00').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar esta saída'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar saída'));
    await tester.pumpAndSettle();
    expect(store.bookings.first.status, 'Concluído');
    expect(store.bookings.last.status, 'Confirmado');
  }, skip: AppConfig.useBackend);

  testWidgets(
    'Detalhe libera WhatsApp após confirmação e avaliação ao concluir',
    (tester) async {
      store.bookings
        ..clear()
        ..add(
          LocalBooking(
            id: 'r1',
            trailId: 't1',
            trailName: 'Roteiro avaliado',
            personName: 'Pessoa de teste',
            date: '10/10/2026',
            status: 'Confirmado',
            roleView: 'turista',
            guidePhone: '(44) 99999-0000',
            agencyId: 'a1',
            agencyName: 'Agência Teste',
          ),
        );
      await tester.pumpWidget(app(const BookingDetailsScreen(bookingId: 'r1')));
      await tester.scrollUntilVisible(
        find.text('Contatar guia pelo WhatsApp'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Contatar guia pelo WhatsApp'), findsOneWidget);
      expect(find.textContaining('Avaliar roteiro'), findsNothing);

      store.bookings.single.status = 'Concluído';
      store.notifyListeners();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Avaliar roteiro, guia e agência'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Avaliar roteiro, guia e agência'));
      await tester.pumpAndSettle();
      expect(find.text('Roteiro'), findsOneWidget);
      expect(find.text('Guia'), findsOneWidget);
      expect(find.text('Agência Teste'), findsOneWidget);
      expect(find.text('0/5'), findsNWidgets(3));
    },
  );

  for (final width in [320.0, 1024.0]) {
    for (final entry in <String, Widget>{
      'guia': const OperatorDashboard(isAgency: false),
      'agencia': const OperatorDashboard(isAgency: true),
      'gestao': const TrailsManagementScreen(isAgency: false),
      'formulario': const TrailFormScreen(isAgency: false),
      'reserva': const BookingDetailsScreen(bookingId: 'r1'),
    }.entries) {
      testWidgets('${entry.key} não transborda em largura $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(key: boundary, child: app(entry.value)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        const previewDirectory = String.fromEnvironment('FRONTEND_PREVIEW_DIR');
        if (previewDirectory.isNotEmpty && width == 320) {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(previewDirectory).create(recursive: true);
            await File(
              '$previewDirectory/${entry.key}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
  testWidgets('Agenda consulta ao abrir e mostra reserva nova após atualizar', (
    tester,
  ) async {
    var calls = 0;
    Future<void> reload() async {
      calls++;
      if (calls > 1) {
        store.bookings.add(
          LocalBooking(
            id: 'r2',
            trailId: 't1',
            trailName: 'Nova reserva remota',
            personName: 'Novo participante',
            date: '26/10/2026',
            status: 'Confirmado',
            roleView: 'turista',
          ),
        );
        // Simula a notificação que refreshBackend publica ao receber o snapshot.
        // ignore: invalid_use_of_protected_member
        store.notifyListeners();
      }
    }

    await tester.pumpWidget(
      app(BookingsScreen(role: 'turista', onRefresh: reload)),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Nova reserva remota'), findsNothing);
    await tester.tap(find.text('Atualizar reservas'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Nova reserva remota'), findsOneWidget);
  });

  testWidgets('Reserva ativa aparece antes do histórico cancelado', (
    tester,
  ) async {
    store.bookings.insert(
      0,
      LocalBooking(
        id: 'cancelada-antiga',
        trailId: 't1',
        trailName: 'Reserva anterior',
        personName: 'Pessoa de teste',
        date: '25/10/2026',
        status: 'Cancelado',
        roleView: 'turista',
      ),
    );

    await tester.pumpWidget(app(const BookingsScreen(role: 'turista')));
    await tester.pumpAndSettle();

    expect(find.text('Reservas ativas'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Reservas ativas')).dy,
      lessThan(tester.getTopLeft(find.text('Histórico')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Confirmado')).dy,
      lessThan(tester.getTopLeft(find.text('Cancelado')).dy),
    );
  });

  testWidgets(
    'Falha de atualização mantém reservas e permite tentar novamente',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          BookingsScreen(
            role: 'turista',
            onRefresh: () async {
              calls++;
              if (calls == 1) throw StateError('API indisponível');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Não foi possível atualizar as reservas.'),
        findsOneWidget,
      );
      expect(store.bookings.single.id, 'r1');
      await tester.tap(find.text('Atualizar reservas'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(
        find.textContaining('Não foi possível atualizar as reservas.'),
        findsNothing,
      );
    },
  );

  testWidgets('Agenda volta a consultar ao retomar o aplicativo', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        BookingsScreen(
          role: 'turista',
          onRefresh: () async {
            calls++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  test(
    'Modo local bloqueia exclusão com reserva ativa e preserva histórico cancelado',
    () async {
      final trail = store.trails.single;
      await expectLater(store.removeTrail(trail), throwsA(isA<StateError>()));
      expect(store.trails.single.id, 't1');
      expect(store.bookings.single.id, 'r1');
      store.bookings.single.status = BookingStatus.cancelled;
      await store.removeTrail(trail);
      expect(store.trails, isEmpty);
      expect(store.bookings.single.status, BookingStatus.cancelled);
    },
    skip: AppConfig.useBackend,
  );
  testWidgets(
    'Cancelamento reduz contador ativo e preserva reserva no histórico',
    (tester) async {
      await tester.pumpWidget(app(const OperatorDashboard(isAgency: false)));
      await tester.pumpAndSettle();
      final metric = find
          .ancestor(
            of: find.text('Reservas ativas'),
            matching: find.byType(Card),
          )
          .first;
      expect(
        find.descendant(of: metric, matching: find.text('1')),
        findsOneWidget,
      );
      await store.cancelBooking(store.bookings.single);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: metric, matching: find.text('0')),
        findsOneWidget,
      );
      expect(store.bookings.single.status, 'Cancelado');
      await tester.pumpWidget(app(const BookingsScreen(role: 'guia')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Trilha de demonstração'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Trilha de demonstração'), findsOneWidget);
      expect(find.text('Cancelado'), findsNothing);
    },
    skip: AppConfig.useBackend,
  );

  for (final scenario in [(const GuideShell(), 1), (const AgencyShell(), 1)]) {
    testWidgets(
      'Ver todos os roteiros mantém rodapé no perfil ${scenario.$2}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: scenario.$1),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Ver todos os roteiros'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Ver todos os roteiros'));
        await tester.pumpAndSettle();
        expect(find.byType(TrailsManagementScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          scenario.$2,
        );
      },
    );
  }
}
