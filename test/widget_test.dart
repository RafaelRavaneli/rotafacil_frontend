import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rotafacil/app.dart';
import 'package:rotafacil/widgets/app_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RotaFácil inicia corretamente', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const RotaFacilApp());

    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump();
    await tester.pumpAndSettle();
    // A marca agora é a imagem do AppLogo (rótulo semântico 'RotaFácil'), não um Text.
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
