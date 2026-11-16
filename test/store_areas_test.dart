import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/pages/tourist/tourist_home_tab.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final store = AppStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await store.initialize();
  });

  /// Conta os avisos de cada área e do store inteiro durante [action].
  Future<Map<String, int>> count(Future<void> Function() action) async {
    final counts = <String, int>{'store': 0};
    final removers = <VoidCallback>[];
    void storeListener() => counts['store'] = counts['store']! + 1;
    store.addListener(storeListener);
    removers.add(() => store.removeListener(storeListener));
    for (final area in StoreArea.values) {
      counts[area.name] = 0;
      void listener() => counts[area.name] = counts[area.name]! + 1;
      store.watch(area).addListener(listener);
      removers.add(() => store.watch(area).removeListener(listener));
    }
    await action();
    for (final remove in removers) {
      remove();
    }
    return counts;
  }

  test('Favoritar avisa só a área de favoritos e o store inteiro', () async {
    final id = store.trails.first.id;
    final counts = await count(() => store.toggleFavorite(id));

    expect(counts['favorites'], 1);
    expect(counts['store'], 1, reason: 'quem escuta o store inteiro continua');
    for (final area in StoreArea.values.where(
      (a) => a != StoreArea.favorites,
    )) {
      expect(counts[area.name], 0, reason: 'área ${area.name}');
    }
  }, skip: AppConfig.useBackend);

  test('Notificação nova avisa só a área de notificações', () async {
    final counts = await count(
      () => store.addNotification(title: 'Teste', body: 'Corpo'),
    );

    expect(counts['notifications'], 1);
    expect(counts['favorites'], 0);
    expect(counts['trails'], 0);
    expect(counts['store'], 1);
  });

  test('Preferência do dispositivo avisa só a área de configurações', () async {
    final counts = await count(
      () => store.setProfileVisible(!store.profileVisible),
    );

    expect(counts['settings'], 1);
    expect(counts['notifications'], 0);
    expect(counts['trails'], 0);
  });

  test('Mudança sem área definida avisa todas as áreas', () async {
    final counts = await count(() async => store.notifyListeners());

    for (final area in StoreArea.values) {
      expect(counts[area.name], 1, reason: 'área ${area.name}');
    }
    expect(counts['store'], 1);
  });

  test('watch devolve o mesmo objeto para o mesmo conjunto de áreas', () {
    expect(
      identical(
        store.watch(StoreArea.trails, StoreArea.favorites),
        store.watch(StoreArea.favorites, StoreArea.trails),
      ),
      isTrue,
    );
    expect(
      identical(
        store.watch(StoreArea.trails),
        store.watch(StoreArea.favorites),
      ),
      isFalse,
    );
  });

  testWidgets('Tela que escuta só notificações não reconstrói ao favoritar', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: store.watch(StoreArea.notifications),
          builder: (context, _) {
            builds++;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(builds, 1);

    await tester.runAsync(() => store.toggleFavorite(store.trails.first.id));
    await tester.pump();
    expect(builds, 1, reason: 'favoritar não afeta notificações');

    await tester.runAsync(
      () => store.addNotification(title: 'Teste', body: 'Corpo'),
    );
    await tester.pump();
    expect(builds, 2);
  }, skip: AppConfig.useBackend);

  testWidgets('Home migrada para áreas ainda atualiza o coração ao favoritar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TouristHomeTab(hasLocationPermission: () async => false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = find.byIcon(Icons.favorite).evaluate().length;

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite).evaluate().length, greaterThan(before));
    expect(tester.takeException(), isNull);
  }, skip: AppConfig.useBackend);
}
