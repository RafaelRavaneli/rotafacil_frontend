import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/app.dart';
import 'package:rotafacil/state/app_store.dart';

void main() {
  testWidgets('RotaFácil inicia corretamente', (
    WidgetTester tester,
  ) async {
    await AppStore.instance.initialize();
    await tester.pumpWidget(const RotaFacilApp());
    await tester.pump();

    expect(find.text('RotaFácil'), findsWidgets);
  });
}
