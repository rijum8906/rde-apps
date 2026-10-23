import 'package:calculator/history.dart';
import 'package:calculator/result_format.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A scrollable list of recent calculations.
class HistoryPanel extends StatelessWidget {
  /// Creates the history panel.
  const new({
    required this.history,
    required this.onSelect,
    required this.onClear,
    super.key,
    this.onClose,
  });

  /// The history to render.
  final CalculatorHistory history;

  /// Called when an entry is tapped.
  final ValueChanged<Calculation> onSelect;

  /// Called when the user clears the history.
  final VoidCallback onClear;

  /// An optional close action, shown in the desktop sidebar.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: history,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('History', style: context.text.emphasisMedium),
                  ),
                  if (!history.isEmpty)
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
            Expanded(
              child: history.isEmpty
                  ? const EmptyState(
                      title: 'No calculations yet',
                      message: 'Results you evaluate are saved here.',
                      icon: Icons.history,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: history.entries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = history.entries[index];
                        return _HistoryEntry(
                          entry: entry,
                          onTap: () => onSelect(entry),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const new({required this.entry, required this.onTap});

  final Calculation entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.expression,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.scale.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatResult(entry.result),
              style: context.text.emphasisMedium,
            ),
          ],
        ),
      ),
    );
  }
}
