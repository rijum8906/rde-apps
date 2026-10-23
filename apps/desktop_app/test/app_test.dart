import 'package:desktop_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the desktop host renders and navigates the shared gallery.
void main() {
  testWidgets('desktop host renders, switches themes, and navigates', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 3000)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DesktopApp());
    await tester.pumpAndSettle();

    expect(find.text('Design System'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);

    final initial = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(initial.themeMode, ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final updated = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(updated.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Open detail page'));
    await tester.pumpAndSettle();

    expect(find.text('Type & shapes'), findsOneWidget);
  });
}
