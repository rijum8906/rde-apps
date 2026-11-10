import 'dart:async';

import 'package:app_shared/app_shared.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_test/app.dart';
import 'package:speed_test/features/settings/data/settings_repository.dart';
import 'package:speed_test/features/speed_test/domain/entities/network_info.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_profile.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_result.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';
import 'package:speed_test/features/speed_test/domain/repositories/speed_test_repository.dart';
import 'package:speed_test/features/speed_test/presentation/model/bandwidth_reading.dart';

/// An in-memory [KeyValueStore] used to verify persistence.
final class _FakeStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<Set<String>> keys() async => values.keys.toSet();

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}

/// A repository whose progress stream the test drives directly.
final class _FakeRepository implements SpeedTestRepository {
  final StreamController<SpeedTestProgress> controller =
      StreamController<SpeedTestProgress>.broadcast();
  final List<SpeedTestResult> stored = <SpeedTestResult>[];
  SpeedTestConfig? lastConfig;

  @override
  Stream<SpeedTestProgress> runTest(SpeedTestConfig config) {
    lastConfig = config;
    return controller.stream;
  }

  @override
  Future<Result<List<SpeedTestResult>, SpeedTestFailure>> loadHistory() async =>
      Result.ok(List<SpeedTestResult>.unmodifiable(stored));

  @override
  Future<Result<void, SpeedTestFailure>> saveResult(
    SpeedTestResult result,
  ) async {
    stored.insert(0, result);
    if (stored.length > maxSpeedTestHistoryEntries) {
      stored.removeLast();
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void, SpeedTestFailure>> clearHistory() async {
    stored.clear();
    return const Result.ok(null);
  }

  Future<void> close() => controller.close();
}

const NetworkInfo _server = NetworkInfo(
  ip: '203.0.113.7',
  city: 'Frankfurt',
  country: 'Germany',
  colo: 'FRA',
  organization: 'Example ISP',
);

SpeedTestProgress _completed({
  double download = 120000000,
  double upload = 25000000,
  double latency = 12.4,
  double jitter = 1.6,
}) {
  return SpeedTestProgress(
    phase: SpeedTestPhase.completed,
    progress: 1,
    liveBps: download,
    downloadBps: download,
    uploadBps: upload,
    latencyMs: latency,
    jitterMs: jitter,
    server: _server,
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required _FakeStore store,
  required _FakeRepository repository,
  Size size = const Size(560, 880),
}) async {
  _setSize(tester, size);
  await tester.pumpWidget(SpeedTestApp(store: store, repository: repository));
  await tester.pumpAndSettle();
}

Finder get _pageScrollable => find.descendant(
  of: find.byKey(const Key('speed-test-list')),
  matching: find.byType(Scrollable),
);

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 200, scrollable: _pageScrollable);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _tapAction(WidgetTester tester) async {
  final action = find.byKey(const Key('speed-test-action'));
  await _scrollTo(tester, action);
  await tester.tap(action);
  await tester.pump();
}

Future<void> _startTest(WidgetTester tester) => _tapAction(tester);

Future<void> _openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(ValueKey<String>('nav-$tab')));
  await tester.pumpAndSettle();
}

Future<String> _metric(WidgetTester tester, String label) async {
  final finder = find.byKey(ValueKey<String>('metric-$label'));
  await _scrollTo(tester, finder);
  return tester.widget<Text>(finder).data!;
}

String _meterValue(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('speed-meter-value'))).data!;

void _setSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

/// Covers the speed test flow, history, settings, and responsive layout.
void main() {
  testWidgets('a completed run updates the gauge and saves history', (
    tester,
  ) async {
    final store = _FakeStore();
    final repository = _FakeRepository();
    addTearDown(repository.close);
    await _pumpApp(tester, store: store, repository: repository);

    expect(_meterValue(tester), '0.0');
    expect(find.text('Ready to test'.toUpperCase()), findsOneWidget);

    await _startTest(tester);
    expect(repository.lastConfig?.profile, SpeedTestProfile.balanced);
    expect(repository.lastConfig?.connections, 4);

    repository.controller.add(
      const SpeedTestProgress(
        phase: SpeedTestPhase.download,
        progress: 0.5,
        liveBps: 60000000,
        downloadBps: 55000000,
        latencyMs: 12.4,
        jitterMs: 1.6,
        server: _server,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('speed-test-progress')), findsOneWidget);
    expect(find.text('Stop test'), findsOneWidget);
    expect(_meterValue(tester), '60.0');

    repository.controller.add(_completed());
    await tester.pumpAndSettle();

    expect(_meterValue(tester), '120');
    expect(await _metric(tester, 'Download'), '120');
    expect(await _metric(tester, 'Upload'), '25.0');
    expect(await _metric(tester, 'Ping'), '12.4');
    expect(await _metric(tester, 'Jitter'), '1.6');
    expect(find.text('Test again'), findsOneWidget);
    expect(repository.stored, hasLength(1));
    expect(repository.stored.single.downloadBps, 120000000);

    await _openTab(tester, 'history');
    expect(find.text('1 of 20 saved'), findsOneWidget);
    expect(find.text('120 Mbps'), findsOneWidget);
    expect(find.text('Frankfurt, Germany'), findsOneWidget);
  });

  testWidgets('stopping a run restores the last saved result', (tester) async {
    final store = _FakeStore();
    final repository = _FakeRepository();
    addTearDown(repository.close);
    await _pumpApp(tester, store: store, repository: repository);

    await _startTest(tester);
    repository.controller.add(
      const SpeedTestProgress(
        phase: SpeedTestPhase.upload,
        progress: 0.8,
        liveBps: 40000000,
        latencyMs: 10,
        jitterMs: 1,
        server: _server,
      ),
    );
    await tester.pump();
    expect(find.text('Stop test'), findsOneWidget);

    await _tapAction(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('speed-test-progress')), findsNothing);
    expect(find.text('Start test'), findsOneWidget);
    expect(_meterValue(tester), '0.0');
    expect(repository.stored, isEmpty);
  });

  testWidgets('history displays the latest run after a restart and clears', (
    tester,
  ) async {
    final store = _FakeStore();
    final repository = _FakeRepository()
      ..stored.add(
        SpeedTestResult(
          timestamp: DateTime(2026, 11, 10, 14, 30),
          downloadBps: 80000000,
          uploadBps: 20000000,
          latencyMs: 18,
          jitterMs: 2.5,
          profile: SpeedTestProfile.quick,
          server: _server,
        ),
      );
    addTearDown(repository.close);
    await _pumpApp(tester, store: store, repository: repository);

    expect(_meterValue(tester), '80.0');
    expect(await _metric(tester, 'Download'), '80.0');
    expect(find.text('Last test'.toUpperCase()), findsOneWidget);

    await _openTab(tester, 'history');
    expect(find.text('Quick'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('No speed tests yet'), findsOneWidget);
    expect(repository.stored, isEmpty);
  });

  testWidgets('the test profile persists and the about page opens', (
    tester,
  ) async {
    final store = _FakeStore();
    final repository = _FakeRepository();
    addTearDown(repository.close);
    await _pumpApp(tester, store: store, repository: repository);

    await _openTab(tester, 'settings');
    expect(find.byKey(const Key('profile-selector')), findsOneWidget);
    await tester.tap(find.text('Thorough'));
    await tester.pumpAndSettle();

    expect(
      store.values[SettingsRepository.storageKey],
      contains('"profile":"thorough"'),
    );
    expect(find.textContaining('200 MB'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('About Speed Test'),
      150,
      scrollable: find.descendant(
        of: find.byKey(const Key('settings-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(find.text('About Speed Test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About Speed Test'));
    await tester.pumpAndSettle();

    expect(find.text('How a test works'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, store: store, repository: repository);
    await _openTab(tester, 'settings');

    final selector = tester.widget<SegmentedButton<SpeedTestProfile>>(
      find.byKey(const Key('profile-selector')),
    );
    expect(selector.selected, {SpeedTestProfile.thorough});
  });

  testWidgets('narrow windows use the navigation bar without overflow', (
    tester,
  ) async {
    final store = _FakeStore();
    final repository = _FakeRepository();
    addTearDown(repository.close);
    await _pumpApp(
      tester,
      store: store,
      repository: repository,
      size: const Size(360, 600),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await _startTest(tester);
    expect(tester.takeException(), isNull);

    await _openTab(tester, 'settings');
    expect(tester.takeException(), isNull);
    await _openTab(tester, 'history');
    expect(tester.takeException(), isNull);
  });

  test('bandwidth readings use the largest sensible unit', () {
    expect(BandwidthReading.fromBps(800).formatted, '800 bps');
    expect(BandwidthReading.fromBps(1500).formatted, '1.5 Kbps');
    expect(BandwidthReading.fromBps(25000000).formatted, '25.0 Mbps');
    expect(BandwidthReading.fromBps(1200000000).formatted, '1.2 Gbps');
    expect(BandwidthReading.fromBps(0).formatted, '0.0 bps');
  });
}
