import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside a minimal themed app.
Widget _host(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

/// Verifies the themed widget wrappers.
void main() {
  testWidgets('AppButton renders every variant and reports taps', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      _host(
        Column(
          children: [
            AppButton(label: 'Filled', onPressed: () => taps++),
            AppButton(
              label: 'Tonal',
              variant: AppButtonVariant.tonal,
              onPressed: () => taps++,
            ),
            AppButton(
              label: 'Outlined',
              variant: AppButtonVariant.outlined,
              onPressed: () => taps++,
            ),
            AppButton(
              label: 'Text',
              variant: AppButtonVariant.text,
              onPressed: () => taps++,
            ),
            const AppButton(label: 'Disabled'),
          ],
        ),
      ),
    );

    // Filled, tonal, and the disabled button share the FilledButton type.
    expect(find.byType(FilledButton), findsNWidgets(3));
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);

    for (final label in ['Filled', 'Tonal', 'Outlined', 'Text']) {
      await tester.tap(find.text(label));
    }
    await tester.pump();

    expect(taps, 4);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );
  });

  testWidgets('AppCard forwards taps through its ink well', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      _host(
        AppCard(onTap: () => tapped = true, child: const Text('Card content')),
      ),
    );

    await tester.tap(find.text('Card content'));
    await tester.pump();

    expect(tapped, isTrue);
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets('AppTextField edits its controller', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(AppTextField(controller: controller, label: 'Name', hint: 'Ada')),
    );

    await tester.enterText(find.byType(TextField), 'Grace');
    await tester.pump();

    expect(controller.text, 'Grace');
    expect(find.text('Name'), findsOneWidget);
  });

  testWidgets('AppDialog resolves to true when confirmed', (tester) async {
    bool? result;

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            return AppButton(
              label: 'Open',
              onPressed: () async {
                result = await AppDialog.show(
                  context,
                  title: 'Delete project?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete project?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Delete project?'), findsNothing);
  });

  testWidgets('AppScaffold shows its title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const AppScaffold(title: 'Workspace', body: Text('Body')),
      ),
    );

    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('EmptyState and AppLoadingIndicator render their content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            AppLoadingIndicator(value: 0.4, label: 'Loading'),
            EmptyState(title: 'Nothing yet', message: 'Add something.'),
          ],
        ),
      ),
    );

    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('Nothing yet'), findsOneWidget);
    expect(find.text('Add something.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppListTile exposes title, subtitle, and tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      _host(
        AppListTile(
          title: 'Settings',
          subtitle: 'Manage the workspace',
          leadingIcon: Icons.settings_outlined,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(tapped, isTrue);
    expect(find.text('Manage the workspace'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
