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
import 'package:rotafacil/pages/management/trail_form_screen.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/theme/app_theme.dart';

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
    expect(find.textContaining('não comprova pagamento'), findsOneWidget);
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

  testWidgets('Detalhe usa registro atualizado e preserva reserva sem trilha', (
    tester,
  ) async {
    store.trails.clear();
    await tester.pumpWidget(app(BookingDetailsScreen(bookingId: 'r1')));
    await tester.scrollUntilVisible(
      find.textContaining('Os dados atuais da trilha não estão disponíveis'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.textContaining('Os dados atuais da trilha não estão disponíveis'),
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
  });

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
}
