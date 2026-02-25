// =============================================================
// ProfileScreen â€” user profile with avatar, name, study goals,
// streak card, and account actions.
// Android rules: resizeToAvoidBottomInset: true (via AppScaffold),
//                enableDrag: false, useSafeArea: true on sheets.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/profile/streak_card.dart';
import 'package:focusflow_mobile/screens/profile/edit_profile_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Local profile preferences not in the UserProfile model
  // ignore: prefer_final_fields  // mutated via setState in _openEditSheet result handler
  String _email = '';
  // ignore: prefer_final_fields
  double _targetHours = 6.0;
  // ignore: prefer_final_fields
  int _targetBlocks = 4;

  // â”€â”€ Open edit sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _openEditSheet(BuildContext context, AppProvider ap) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      enableDrag: false,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        profile: ap.userProfile,
        currentEmail: _email,
        currentTargetHours: _targetHours,
        currentTargetBlocks: _targetBlocks,
      ),
    );
    if (result == true && mounted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // â”€â”€ Avatar initials â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final profile = ap.userProfile;
    final name = profile?.displayName ?? 'Your Name';

    // Derived stats from provider data
    final totalMinutes = ap.timeLogs.fold<int>(0, (sum, t) => sum + t.durationMinutes);
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);
    final completedBlocks = ap.dayPlans
        .expand((p) => p.blocks ?? [])
        .where((b) => b.status.value == 'DONE')
        .length;

    return AppScaffold(
      screenName: 'Profile',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, size: 20),
          tooltip: 'Edit profile',
          onPressed: () => _openEditSheet(context, ap),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // AVATAR + NAME
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          Center(
            child: Column(
              children: [
                // Avatar with edit button
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary.withValues(alpha: 0.15),
                        border: Border.all(
                            color: cs.primary.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _initials(name),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _openEditSheet(context, ap),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: cs.surface, width: 2),
                          ),
                          child: Icon(Icons.edit_rounded,
                              size: 14, color: cs.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Display name
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),

                // Email (local only)
                if (_email.isNotEmpty)
                  Text(
                    _email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _openEditSheet(context, ap),
                    icon: Icon(Icons.add_rounded, size: 14, color: cs.primary),
                    label: const Text('Add email'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      textStyle: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // STREAK CARD
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _sectionLabel('Activity Streak', theme, cs),
          const SizedBox(height: 8),
          StreakCard(ap: ap),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // STUDY STATS
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _sectionLabel('Study Stats', theme, cs),
          const SizedBox(height: 8),
          _StatsGrid(
            items: [
              _StatItem(
                icon: Icons.timer_rounded,
                label: 'Total Hours',
                value: totalHours,
                color: Colors.blue.shade400,
              ),
              _StatItem(
                icon: Icons.check_circle_rounded,
                label: 'Blocks Done',
                value: '$completedBlocks',
                color: Colors.green.shade400,
              ),
              _StatItem(
                icon: Icons.schedule_rounded,
                label: 'Target / day',
                value: '${_targetHours.toStringAsFixed(1)}h',
                color: cs.primary,
              ),
              _StatItem(
                icon: Icons.grid_view_rounded,
                label: 'Blocks / day',
                value: '$_targetBlocks',
                color: Colors.orange.shade400,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // STUDY GOAL SETTINGS
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _sectionLabel('Daily Goals', theme, cs),
          const SizedBox(height: 8),
          _GoalRow(
            icon: Icons.access_time_rounded,
            label: 'Study hours target',
            value: '${_targetHours.toStringAsFixed(1)} hrs / day',
            cs: cs,
            theme: theme,
            onTap: () => _openEditSheet(context, ap),
          ),
          const SizedBox(height: 8),
          _GoalRow(
            icon: Icons.view_agenda_rounded,
            label: 'Blocks target',
            value: '$_targetBlocks blocks / day',
            cs: cs,
            theme: theme,
            onTap: () => _openEditSheet(context, ap),
          ),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // ACCOUNT ACTIONS
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _sectionLabel('Account', theme, cs),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.backup_rounded,
            label: 'Backup Data',
            iconColor: cs.primary,
            cs: cs,
            theme: theme,
            onTap: () => _showPlaceholder(context, 'Backup'),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            iconColor: cs.error,
            cs: cs,
            theme: theme,
            onTap: () => _showPlaceholder(context, 'Sign out'),
            danger: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action â€” coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HELPER WIDGETS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

Widget _sectionLabel(String label, ThemeData theme, ColorScheme cs) {
  return Text(
    label,
    style: theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface.withValues(alpha: 0.5),
    ),
  );
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(item.icon, size: 16, color: item.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final ThemeData theme;
  final VoidCallback onTap;

  const _GoalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: cs.onSurface.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final ColorScheme cs;
  final ThemeData theme;
  final VoidCallback onTap;
  final bool danger;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.cs,
    required this.theme,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: danger
              ? cs.error.withValues(alpha: 0.04)
              : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: danger
                ? cs.error.withValues(alpha: 0.15)
                : cs.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: danger ? cs.error : cs.onSurface,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }
}
