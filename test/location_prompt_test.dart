import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/pages/tourist/tourist_home_tab.dart';
import 'package:rotafacil/services/location_service.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/widgets/skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStore.instance.initialize();
  });

  Widget home({
    Future<bool> Function()? hasPermission,
    Future<UserCoordinates> Function()? locate,
  }) => MaterialApp(
    home: Scaffold(
      body: TouristHomeTab(
        hasLocationPermission: hasPermission,
        locate: locate,
      ),
    ),
  );

  testWidgets(
    'Sem permissão concedida a home convida, sem pedir a localização',
    (tester) async {
      var captures = 0;
      await tester.pumpWidget(
        home(
          hasPermission: () async => false,
          locate: () async {
            captures++;
            return const UserCoordinates(latitude: -23.4, longitude: -51.9);
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(captures, 0);
      expect(find.text('Usar minha localização'), findsOneWidget);
      expect(
        find.textContaining('só para calcular as distâncias'),
        findsOneWidget,
      );
      // O convite substitui a mensagem de erro e o "Tentar novamente".
      expect(find.text('Tentar novamente'), findsNothing);
      expect(find.textContaining('bloqueada'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tocar em Usar minha localização captura a posição', (
    tester,
  ) async {
    var captures = 0;
    await tester.pumpWidget(
      home(
        hasPermission: () async => false,
        locate: () async {
          captures++;
          return const UserCoordinates(latitude: -23.4, longitude: -51.9);
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Usar minha localização'));
    await tester.tap(find.text('Usar minha localização'));
    await tester.pumpAndSettle();

    expect(captures, 1);
    expect(find.text('Usar minha localização'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Voltar ao app com posição recente não pede a localização de novo',
    (tester) async {
      var captures = 0;
      await tester.pumpWidget(
        home(
          hasPermission: () async => true,
          locate: () async {
            captures++;
            return const UserCoordinates(latitude: -23.4, longitude: -51.9);
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(captures, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(captures, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Enquanto localiza, mostra esqueleto dos cartões e não um indicador',
    (tester) async {
      final pending = Completer<UserCoordinates>();
      await tester.pumpWidget(
        home(hasPermission: () async => true, locate: () => pending.future),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TrailCardSkeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      pending.complete(
        const UserCoordinates(latitude: -23.4, longitude: -51.9),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TrailCardSkeleton), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
