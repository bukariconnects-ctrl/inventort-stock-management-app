import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/core/constants/app_constants.dart';
import 'package:inventory_app/main.dart';

void main() {
  testWidgets('Rawaa WMS smoke test', (WidgetTester tester) async {
    // بناء التطبيق وإطلاق الإطار
    await tester.pumpWidget(const RawaaWmsApp());
    await tester.pumpAndSettle();

    // التحقق من ظهور اسم التطبيق والعلامة التجارية
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
    expect(find.text(AppConstants.defaultItemName), findsOneWidget);
  });
}
