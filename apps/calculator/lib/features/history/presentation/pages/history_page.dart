import 'package:app_routing/app_routing.dart';
import 'package:calculator/features/calculator/data/datasources/calculator_local_data_source.dart';
import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_bloc.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_event.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_state.dart';
import 'package:calculator/features/history/presentation/widgets/history_list.dart';
import 'package:calculator/routing/calculator_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The history page: every persisted calculation, newest first.
class HistoryPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final entries = state.history;
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
                  title: 'No calculations yet',
                  message:
                      'Results you evaluate are saved on this device, newest '
                      'first.',
                  icon: Icons.history,
                  action: AppButton(
                    label: 'Open calculator',
                    icon: Icons.calculate_outlined,
                    variant: AppButtonVariant.tonal,
                    onPressed: () => context.goTo(CalculatorRoutes.calculator),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entries.length} of '
                      '${CalculatorLocalDataSource.maxEntries} saved',
                      style: context.text.scale.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: HistoryList(
                          entries: entries,
                          onSelect: (entry) => _reuse(context, entry),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _reuse(BuildContext context, Calculation entry) {
    context.read<CalculatorBloc>().add(LoadCalculation(entry));
    context.goTo(CalculatorRoutes.calculator);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bloc = context.read<CalculatorBloc>();
    final confirmed = await AppDialog.show(
      context,
      title: 'Clear history?',
      message: 'Every saved calculation is removed from this device.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (confirmed ?? false) {
      bloc.add(const ClearHistory());
    }
  }
}
