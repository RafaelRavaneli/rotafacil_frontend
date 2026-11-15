import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotafacil/widgets/expandable_info_section.dart';

void main() {
  Widget app({bool expanded = false}) => MaterialApp(
    home: Scaffold(
      body: ExpandableInfoSection(
        title: 'O que levar',
        initiallyExpanded: expanded,
        child: const Text('Água'),
      ),
    ),
  );

  testWidgets('começa fechada e abre ao tocar no título', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('O que levar'), findsOneWidget);
    expect(find.text('Água'), findsNothing);

    await tester.tap(find.text('O que levar'));
    await tester.pumpAndSettle();
    expect(find.text('Água'), findsOneWidget);

    await tester.tap(find.text('O que levar'));
    await tester.pumpAndSettle();
    expect(find.text('Água'), findsNothing);
  });

  testWidgets('pode começar aberta', (tester) async {
    await tester.pumpWidget(app(expanded: true));
    expect(find.text('Água'), findsOneWidget);
  });
}
