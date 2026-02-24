// =============================================================
// RestoreConfirmDialog — confirm dialog before restoring data.
// Warning icon, destructive message, Cancel + Restore buttons.
// =============================================================

import 'package:flutter/material.dart';

class RestoreConfirmDialog extends StatelessWidget {
  /// Called when the user confirms the restore action.
  final VoidCallback onConfirm;

  const RestoreConfirmDialog({super.key, required this.onConfirm});

  /// Show the dialog and return true if user confirmed.
  static Future<bool?> show(BuildContext context, VoidCallback onConfirm) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RestoreConfirmDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cs.surface,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded,
                size: 32, color: cs.error),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Restore Backup?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            'This will replace all current data with the backup data. '
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        // Cancel
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ),

        // Restore
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Restore'),
        ),
      ],
    );
  }
}
