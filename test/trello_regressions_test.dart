import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/app.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/models/guide.dart';
import 'package:rotafacil/models/trail.dart';
import 'package:rotafacil/pages/common/notification_center_screen.dart';
import 'package:rotafacil/pages/common/settings/notifications_screen.dart';
import 'package:rotafacil/pages/tourist/tourist_home_tab.dart';
import 'package:rotafacil/services/location_service.dart';
import 'package:rotafacil/services/session_service.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/widgets/trail_card.dart';
import 'package:rotafacil/widgets/profile_avatar.dart';
import 'package:rotafacil/models/app_user.dart';

class _Location extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.deniedForever;
  int captures = 0;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    captures++;
    return Position(
      latitude: -23.4,
      longitude: -51.9,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  final originalLocation = GeolocatorPlatform.instance;
  late _Location location;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.instance.clear();
    await AppStore.instance.initialize();
    location = _Location();
    GeolocatorPlatform.instance = location;
  });
  tearDown(() {
    GeolocatorPlatform.instance = originalLocation;
  });

  test('Permissão revogada invalida uso da posição recente', () async {
    location.permission = LocationPermission.whileInUse;
    await LocationService.instance.capture();
    expect(location.captures, 1);
    location.permission = LocationPermission.deniedForever;
    await expectLater(
      LocationService.instance.capture(),
      throwsA(isA<StateError>()),
    );
    expect(location.captures, 1);
  });

  test('Perfil público carrega média real e foto remota após restauração', () {
    final guide = GuideProfile.fromJson({
      'id': 'g',
      'nota_media': 4.5,
      'total_avaliacoes': 2,
    });
    expect(guide.rating, 4.5);
    expect(guide.reviews, 2);
    final user = AppUser.fromJson({
      'nome': 'Ana',
      'tipo': 'usuario',
      'foto_url': 'https://example.test/avatar.jpg',
    });
    expect(user.profileImageDataUrl, 'https://example.test/avatar.jpg');
  });

  testWidgets('Foto restaurada usa a URL salva sem depender de bytes locais', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileAvatar(dataUrl: 'https://example.test/avatar.jpg'),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'https://example.test/avatar.jpg',
    );
  });

  testWidgets('Central permite abrir preferências e atualizar mesmo vazia', (
    tester,
  ) async {
    AppStore.instance.notifications.clear();
    await tester.pumpWidget(
      const MaterialApp(home: NotificationCenterScreen()),
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
    await tester.tap(find.byTooltip('Preferências de notificações'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
  }, skip: AppConfig.useBackend);

  testWidgets('Avaliação zero continua no carrossel e aparece no card', (
    tester,
  ) async {
    AppStore.instance.trails
      ..clear()
      ..add(
        Trail.fromJson({
          'id': 'zero',
          'nome': 'Avaliação zero real',
          'nota_media': 0,
          'total_avaliacoes': 1,
          'ativo': true,
        }),
      );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TouristHomeTab())),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TrailCard),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Avaliação zero real'), findsOneWidget);
    expect(find.text('0,0'), findsOneWidget);
  }, skip: AppConfig.useBackend);

  for (final entry in {
    '/roteiros/t1/inscritos': 'Inscritos no roteiro',
    '/roteiros/t1/editar': 'Editar roteiro',
    '/roteiro/t1': 'Roteiro de teste',
  }.entries) {
    testWidgets('URL direta mantém destino ${entry.key}', (tester) async {
      await SessionService.instance.save(
        selectedRole: 'guia',
        userEmail: 'guia@example.test',
        id: 'g',
      );
      AppStore.instance.guide.email = 'guia@example.test';
      AppStore.instance.trails
        ..clear()
        ..add(
          Trail.fromJson({
            'id': 't1',
            'nome': 'Roteiro de teste',
            'criado_por': 'guia@example.test',
            'id_guia': 'g',
          }),
        );
      tester.binding.platformDispatcher.defaultRouteNameTestValue = entry.key;
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      await tester.pumpWidget(const RotaFacilApp());
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }, skip: AppConfig.useBackend);
  }
}
