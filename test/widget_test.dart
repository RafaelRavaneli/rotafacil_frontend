import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rotafacil/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RotaFácil inicia corretamente', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const RotaFacilApp());

    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
