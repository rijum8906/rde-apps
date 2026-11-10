import 'package:app_theme/app_theme.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speed_test/features/settings/presentation/settings_cubit.dart';
import 'package:speed_test/features/speed_test/domain/entities/network_info.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_profile.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_bloc.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_event.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_state.dart';
import 'package:speed_test/features/speed_test/presentation/model/bandwidth_reading.dart';
import 'package:speed_test/features/speed_test/presentation/model/speed_meter_model.dart';
import 'package:speed_test/features/speed_test/presentation/widgets/metric_card.dart';
import 'package:speed_test/features/speed_test/presentation/widgets/phase_chip.dart';
import 'package:speed_test/features/speed_test/presentation/widgets/speed_meter.dart';

/// The speed test page: dial, live phase progress, and the result metrics.
///
/// This is the only widget that touches [SpeedTestBloc]; the gauge and metric
/// cards are driven entirely by the values it passes down.
class SpeedTestPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SpeedTestBloc>().state;
    final profile = context.watch<SettingsCubit>().state;
    final theme = AppThemeScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = SpeedMeterModel.fromState(state);

    return AppScaffold(
      title: 'Speed Test',
      actions: [
        IconButton(
          key: const Key('theme-toggle'),
          tooltip: isDark ? 'Use light theme' : 'Use dark theme',
          onPressed: () =>
              theme.setMode(isDark ? ThemeMode.light : ThemeMode.dark),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            key: const Key('speed-test-list'),
            children: [
              _ServerHeader(server: state.server, state: state),
              const SizedBox(height: 8),
              SpeedMeter(model: model),
              const SizedBox(height: 8),
              _StatusArea(state: state),
              const SizedBox(height: 16),
              AppButton(
                key: const Key('speed-test-action'),
                label: state.isRunning
                    ? 'Stop test'
                    : state.hasResult
                    ? 'Test again'
                    : 'Start test',
                icon: state.isRunning
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
                variant: state.isRunning
                    ? AppButtonVariant.outlined
                    : AppButtonVariant.filled,
                expand: true,
                onPressed: () => _toggle(context, profile),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '${profile.label} profile · '
                  '${_megabytes(profile.downloadMegabytes)} down / '
                  '${_megabytes(profile.uploadMegabytes)} up',
                  textAlign: TextAlign.center,
                  style: context.text.scale.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _MetricsGrid(state: state),
              const SizedBox(height: 16),
              const _PrivacyNote(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(BuildContext context, SpeedTestProfile profile) {
    final bloc = context.read<SpeedTestBloc>();
    if (bloc.state.isRunning) {
      bloc.add(const CancelSpeedTest());
    } else {
      bloc.add(StartSpeedTest(SpeedTestConfig(profile: profile)));
    }
  }

  static String _megabytes(double value) => '${value.toStringAsFixed(0)} MB';
}

class _ServerHeader extends StatelessWidget {
  const new({required this.server, required this.state});

  final NetworkInfo? server;
  final SpeedTestState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final details = [
      ?server?.location,
      if (server?.colo case final colo?) 'edge $colo',
      ?server?.organization,
    ];
    final title = switch (server?.provider) {
      'Fast.com' => 'Nearest Netflix server',
      null => 'Speed test network',
      _ => 'Nearest Cloudflare edge',
    };

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_outlined,
              size: 20,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.emphasisSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  details.isEmpty
                      ? 'Global anycast network'
                      : details.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.scale.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(state: state),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const new({required this.state});

  final SpeedTestState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, background, foreground) = switch (state.phase) {
      _ when state.isRunning => (
        'Live',
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      SpeedTestPhase.completed => (
        'Done',
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      SpeedTestPhase.failed => (
        'Failed',
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      _ => ('Ready', colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.shapes.extraSmall),
      ),
      child: Text(
        label,
        style: context.text.scale.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusArea extends StatelessWidget {
  const new({required this.state});

  final SpeedTestState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final phaseIndex = _phaseIndex(state);

    return Column(
      children: [
        if (state.errorMessage case final message?) ...[
          Container(
            key: const Key('speed-test-error'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(context.shapes.small),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: colors.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: context.text.scale.bodySmall?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (state.isRunning) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  _phaseLabel(state.phase),
                  style: context.text.emphasisSmall,
                ),
              ),
              Text(
                '${(state.progress * 100).round()}%',
                style: context.text.scale.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: const Key('speed-test-progress'),
              value: state.progress,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            PhaseChip(
              label: 'Ping',
              icon: Icons.network_ping,
              status: _statusFor(1, phaseIndex),
            ),
            PhaseChip(
              label: 'Download',
              icon: Icons.arrow_downward,
              status: _statusFor(2, phaseIndex),
            ),
            PhaseChip(
              label: 'Upload',
              icon: Icons.arrow_upward,
              status: _statusFor(3, phaseIndex),
            ),
          ],
        ),
        if (!state.isRunning && state.result != null) ...[
          const SizedBox(height: 10),
          Text(
            'Saved on this device. Open History to compare runs.',
            textAlign: TextAlign.center,
            style: context.text.scale.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  static int _phaseIndex(SpeedTestState state) {
    if (state.phase == SpeedTestPhase.completed) {
      return 4;
    }
    if (state.phase == SpeedTestPhase.failed) {
      return state.hasResult ? 4 : 0;
    }
    return switch (state.phase) {
      SpeedTestPhase.connecting => 0,
      SpeedTestPhase.latency => 1,
      SpeedTestPhase.download => 2,
      SpeedTestPhase.upload => 3,
      _ => state.hasResult ? 4 : 0,
    };
  }

  static PhaseStatus _statusFor(int phase, int current) {
    if (current >= phase + 1) {
      return PhaseStatus.done;
    }
    if (current == phase) {
      return PhaseStatus.active;
    }
    return PhaseStatus.pending;
  }

  static String _phaseLabel(SpeedTestPhase phase) => switch (phase) {
    SpeedTestPhase.connecting => 'Connecting to the server',
    SpeedTestPhase.latency => 'Measuring ping and jitter',
    SpeedTestPhase.download => 'Measuring download speed',
    SpeedTestPhase.upload => 'Measuring upload speed',
    _ => 'Finishing up',
  };
}

class _MetricsGrid extends StatelessWidget {
  const new({required this.state});

  final SpeedTestState state;

  @override
  Widget build(BuildContext context) {
    final download = state.downloadBps == null
        ? null
        : BandwidthReading.fromBps(state.downloadBps!);
    final upload = state.uploadBps == null
        ? null
        : BandwidthReading.fromBps(state.uploadBps!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Download',
                value: download?.formattedValue ?? '—',
                unit: download?.unit ?? '',
                icon: Icons.arrow_downward,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Upload',
                value: upload?.formattedValue ?? '—',
                unit: upload?.unit ?? '',
                icon: Icons.arrow_upward,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Ping',
                value: _milliseconds(state.latencyMs),
                unit: state.latencyMs == null ? '' : 'ms',
                icon: Icons.network_ping,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Jitter',
                value: _milliseconds(state.jitterMs),
                unit: state.jitterMs == null ? '' : 'ms',
                icon: Icons.show_chart,
              ),
            ),
          ],
        );
      },
    );
  }

  static String _milliseconds(double? value) {
    if (value == null) {
      return '—';
    }
    return value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

class _PrivacyNote extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Traffic is measured against Fast.com's Netflix Open Connect "
              'network, with Cloudflare as a fallback. No account is required, '
              'and your results and preferences stay on this device.',
              style: context.text.scale.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
