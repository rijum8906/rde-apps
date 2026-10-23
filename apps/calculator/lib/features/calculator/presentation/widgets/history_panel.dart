import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/result_format.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Material 3 side-sheet content for recent calculations.
class HistoryPanel extends StatelessWidget {
  const new({
    required this.entries,
    required this.onSelect,
    required this.onClear,
    super.key,
    this.onClose,
  });

  final List<Calculation> entries;
  final ValueChanged<Calculation> onSelect;
  final VoidCallback onClear;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (entries.isNotEmpty)
                IconButton(
                  tooltip: 'Clear history',
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline),
                ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close history',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
        Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        Expanded(
          child: entries.isEmpty
              ? const EmptyState(
                  title: 'No calculations yet',
                  message: 'Results you evaluate are saved here.',
                  icon: Icons.history,
                )
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      onTap: () => onSelect(entry),
                      title: Text(
                        entry.expression,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        formatResult(entry.result),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
