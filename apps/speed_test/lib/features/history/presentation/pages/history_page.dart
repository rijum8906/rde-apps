import 'package:app_routing/app_routing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_result.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_bloc.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_event.dart';
import 'package:speed_test/features/speed_test/presentation/model/bandwidth_reading.dart';
import 'package:speed_test/routing/speed_test_routes.dart';

/// Every persisted speed test, newest first.
class HistoryPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<SpeedTestBloc>().state.history;
    return AppScaffold(
      title: 'History',
      actions: [
        if (entries.isNotEmpty)
          IconButton(
            key: const Key('history-clear'),
            tooltip: 'Clear history',
            onPressed: () => _confirmClear(context),
            icon: const Icon(Icons.delete_outline),
          ),
      ],
      body: entries.isEmpty
          ? EmptyState(
              title: 'No speed tests yet',
              message:
                  'Run a test and the result is saved here, newest first, so '
                  'you can compare connections over time.',
              icon: Icons.speed,
              action: AppButton(
                label: 'Run a test',
                icon: Icons.play_circle_outline,
                variant: AppButtonVariant.tonal,
                onPressed: () => context.goTo(SpeedTestRoutes.speedTest),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entries.length} of $maxSpeedTestHistoryEntries saved',
                  style: context.text.scale.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    key: const Key('history-list'),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _HistoryCard(result: entries[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bloc = context.read<SpeedTestBloc>();
    final confirmed = await AppDialog.show(
      context,
      title: 'Clear history?',
      message: 'Every saved speed test is removed from this device.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (confirmed ?? false) {
      bloc.add(const ClearSpeedTestHistory());
    }
  }
}

class _HistoryCard extends StatelessWidget {
  const new({required this.result});

  final SpeedTestResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final server = result.server;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _timestamp(context, result.timestamp),
                  style: context.text.scale.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    context.shapes.extraSmall,
                  ),
                ),
                child: Text(
                  result.profile.label,
                  style: context.text.scale.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HistoryMetric(
                  label: 'Download',
                  value: formatBandwidth(result.downloadBps),
                  icon: Icons.arrow_downward,
                ),
              ),
              Expanded(
                child: _HistoryMetric(
                  label: 'Upload',
                  value: formatBandwidth(result.uploadBps),
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Detail(
                icon: Icons.network_ping,
                text: 'Ping ${formatMilliseconds(result.latencyMs)}',
              ),
              _Detail(
                icon: Icons.show_chart,
                text: 'Jitter ${formatMilliseconds(result.jitterMs)}',
              ),
              if (server?.location case final location?)
                _Detail(icon: Icons.place_outlined, text: location),
            ],
          ),
        ],
      ),
    );
  }

  static String _timestamp(BuildContext context, DateTime timestamp) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(timestamp);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(timestamp),
    );
    return '$date · $time';
  }
}

class _HistoryMetric extends StatelessWidget {
  const new({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: colors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: context.text.scale.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: context.text.scale.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: context.text.scale.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
