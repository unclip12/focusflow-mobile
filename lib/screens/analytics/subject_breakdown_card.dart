// =============================================================
// SubjectBreakdownCard — horizontal progress-bar list
// Shows each subject's study hours with filled bar + % label.
// Data from AppProvider.getSubjectBreakdown(days).
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/core/theme/app_colors.dart';

/// Single subject data entry.
class SubjectEntry {
  final String subject;
  final double hours;
  final double fraction; // 0.0 – 1.0
  final int percentage;

  const SubjectEntry({
    required this.subject,
    required this.hours,
    required this.fraction,
    required this.percentage,
  });
}

class SubjectBreakdownCard extends StatelessWidget {
  final List<SubjectEntry> subjects;
  final String rangeBadge;

  const SubjectBreakdownCard({
    super.key,
    required this.subjects,
    required this.rangeBadge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    if (subjects.isEmpty) {
      return _emptyState(context);
    }

    return Column(
      children: List.generate(subjects.length, (i) {
        final entry = subjects[i];
        final color = AppColors.subjectColors[
            entry.subject.hashCode.abs() % AppColors.subjectColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Label row ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.subject,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.hours.toStringAsFixed(1)}h · ${entry.percentage}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:      color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // ── Progress bar ───────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           entry.fraction,
                  minHeight:       8,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.07),
                  valueColor:      AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'No subject data for $rangeBadge',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
