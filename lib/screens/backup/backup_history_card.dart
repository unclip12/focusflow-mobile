// =============================================================
// BackupHistoryCard — card showing backup date, file size,
// restore text button, and delete icon with confirm dialog.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackupHistoryCard extends StatelessWidget {
  final String date;
  final String size;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const BackupHistoryCard({
    super.key,
    required this.date,
    required this.size,
    required this.onRestore,
    required this.onDelete,
  });

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Backup?'),
          content: const Text('This backup will be permanently removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                onDelete();
              },
              child: Text('Delete',
                  style: TextStyle(color: cs.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Backup icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.cloud_done_rounded,
                size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),

          // Date + size
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  size,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),

          // Restore button
          TextButton(
            onPressed: onRestore,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              textStyle: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Restore'),
          ),

          // Delete icon
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 18, color: cs.error.withValues(alpha: 0.6)),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Delete backup',
            constraints: const BoxConstraints(
                minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
