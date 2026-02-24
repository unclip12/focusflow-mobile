// =============================================================
// NotificationsScreen — scrollable notification center
// Groups by: Today / Yesterday / Older.
// Header shows unread count badge + settings gear.
// Empty state with illustration when list is empty.
// Android rules: resizeToAvoidBottomInset: true (AppScaffold).
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/notifications/notification_card.dart';
import 'package:focusflow_mobile/screens/notifications/notification_settings_sheet.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // ── Date bucket helpers ────────────────────────────────────────
  static bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static bool _isYesterday(DateTime dt) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
  }

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final notifications = app.notifications;
    final unreadCount   = notifications.where((n) => !n.isRead).length;

    // ── Partition into groups ─────────────────────────────────────
    final today     = notifications.where((n) => _isToday(n.createdAt)).toList();
    final yesterday = notifications.where((n) => _isYesterday(n.createdAt)).toList();
    final older     = notifications
        .where((n) => !_isToday(n.createdAt) && !_isYesterday(n.createdAt))
        .toList();

    return AppScaffold(
      screenName: 'Notifications',
      actions: [
        // ── Unread badge ────────────────────────────────────────
        if (unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color:      cs.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        // ── Settings gear ───────────────────────────────────────
        IconButton(
          icon: Icon(Icons.tune_rounded,
              size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
          onPressed: () => showNotificationSettingsSheet(context),
          tooltip: 'Notification settings',
        ),
        // ── Mark all read ───────────────────────────────────────
        if (unreadCount > 0)
          IconButton(
            icon: Icon(Icons.done_all_rounded,
                size: 20, color: cs.primary),
            onPressed: () => app.markAllNotificationsRead(),
            tooltip: 'Mark all as read',
          ),
      ],
      body: notifications.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (today.isNotEmpty) ...[
                  _GroupHeader('Today'),
                  const SizedBox(height: 6),
                  ...today.map((n) => NotificationCard(notification: n)),
                  const SizedBox(height: 12),
                ],
                if (yesterday.isNotEmpty) ...[
                  _GroupHeader('Yesterday'),
                  const SizedBox(height: 6),
                  ...yesterday.map((n) => NotificationCard(notification: n)),
                  const SizedBox(height: 12),
                ],
                if (older.isNotEmpty) ...[
                  _GroupHeader('Older'),
                  const SizedBox(height: 6),
                  ...older.map((n) => NotificationCard(notification: n)),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ── Section group header ──────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:       Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            fontWeight:  FontWeight.w700,
            letterSpacing: 0.8,
          ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Bell illustration ─────────────────────────────
            Container(
              width:  96,
              height: 96,
              decoration: BoxDecoration(
                color:  cs.primary.withValues(alpha: 0.08),
                shape:  BoxShape.circle,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 52,
                        color: cs.primary.withValues(alpha: 0.35)),
                    Positioned(
                      top:   14,
                      right: 14,
                      child: Container(
                        width:  14,
                        height: 14,
                        decoration: BoxDecoration(
                          color:  cs.primary.withValues(alpha: 0.2),
                          shape:  BoxShape.circle,
                          border: Border.all(
                              color: cs.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All caught up!',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'No notifications yet.\nYou\'ll see reminders, achievements, and revision alerts here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color:  cs.onSurface.withValues(alpha: 0.45),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
