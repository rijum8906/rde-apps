import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/result_format.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A scrollable, selectable list of completed calculations, newest first.
class HistoryList extends StatelessWidget {
  /// Creates the list.
  const new({required this.entries, required this.onSelect, super.key});

  /// The calculations to render, newest first.
  final List<Calculation> entries;

  /// Called when an entry is tapped.
  final ValueChanged<Calculation> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _HistoryEntryTile(
          key: ValueKey('history-entry-$index'),
          entry: entry,
          onTap: () => onSelect(entry),
        );
      },
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const new({required this.entry, required this.onTap, super.key});

  final Calculation entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
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
                  const SizedBox(height: 4),
                  Text(
                    '= ${formatResult(entry.result)}',
                    style: context.text.emphasisMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.north_east, size: 18, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
