import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393/app/app.dart';

void main() {
  testWidgets('Flower shop app renders the auth bootstrap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowerShopApp());
    await tester.pump();

    expect(find.byType(FlowerShopApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
