// =============================================================
// UWorld Tab — Premium redesigned UWorld questions tracker
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/screens/tracker/tracker_sheets.dart';
import 'package:focusflow_mobile/screens/library/uworld_detail_sheet.dart';

class UWorldTab extends StatelessWidget {
  final AppProvider app;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  final String searchQuery;

  const UWorldTab({
    super.key,
    required this.app,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (app.uworldTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.quiz_rounded,
              size: 56,
              color: DashboardColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No UWorld topics loaded',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add UWorld topics to track your progress',
              style: TextStyle(
                fontSize: 13,
                color: DashboardColors.textPrimary(isDark)
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    var topics = List<UWorldTopic>.from(app.uworldTopics)
      ..sort((a, b) => a.system.compareTo(b.system));

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      topics = topics
          .where((t) =>
              t.subtopic.toLowerCase().contains(q) ||
              t.system.toLowerCase().contains(q))
          .toList();
    }

    // Calculate overall stats
    int totalDone = 0, totalQuestions = 0, totalCorrect = 0;
    for (final t in app.uworldTopics) {
      totalDone += t.doneQuestions;
      totalQuestions += t.totalQuestions;
      totalCorrect += t.correctQuestions;
    }
    final accuracy =
        totalDone > 0 ? ((totalCorrect / totalDone) * 100).round() : 0;

    // Group by system
    final systemOrder = <String>[];
    final grouped = <String, List<UWorldTopic>>{};
    for (final t in topics) {
      final sys = t.system.isEmpty ? 'Uncategorized' : t.system;
      if (!grouped.containsKey(sys)) {
        systemOrder.add(sys);
        grouped[sys] = [];
      }
      grouped[sys]!.add(t);
    }

    return Column(
      children: [
        // ── Stats header ─────────────────────────────────
        _UWorldStatsHeader(
          totalDone: totalDone,
          totalQuestions: totalQuestions,
          accuracy: accuracy,
          isDark: isDark,
        ),

        // ── System list ──────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
              top: 4,
            ),
            itemCount: systemOrder.length,
            itemBuilder: (context, i) {
              final system = systemOrder[i];
              final sysTopics = grouped[system]!;

              int sysDone = 0, sysTotal = 0, sysCorrect = 0;
              for (final t in sysTopics) {
                sysDone += t.doneQuestions;
                sysTotal += t.totalQuestions;
                sysCorrect += t.correctQuestions;
              }
              final sysAccuracy =
                  sysDone > 0 ? ((sysCorrect / sysDone) * 100).round() : 0;
              final sysProgress =
                  sysTotal > 0 ? sysDone / sysTotal : 0.0;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: DashboardColors.glassBorder(isDark),
                        width: 0.5,
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: systemOrder.length <= 5 || searchQuery.isNotEmpty,
                        tilePadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        title: Text(
                          system,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DashboardColors.textPrimary(isDark),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Accuracy chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accuracyColor(sysAccuracy)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$sysAccuracy%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _accuracyColor(sysAccuracy),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$sysDone/$sysTotal',
                              style: TextStyle(
                                fontSize: 12,
                                color: DashboardColors.textPrimary(isDark)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                value: sysProgress,
                                strokeWidth: 2.5,
                                strokeCap: StrokeCap.round,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : DashboardColors.primary
                                        .withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _accuracyColor(sysAccuracy),
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: sysTopics.map((topic) {
                          return _buildTopicTile(context, topic, isDark);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopicTile(
      BuildContext context, UWorldTopic topic, bool isDark) {
    final key = 'uworld:${topic.id}';
    final isSelected = selectedItems.contains(key);
    final progress = topic.totalQuestions > 0
        ? topic.doneQuestions / topic.totalQuestions
        : 0.0;
    final accuracy = topic.doneQuestions > 0
        ? ((topic.correctQuestions / topic.doneQuestions) * 100).round()
        : 0;
    final remaining = topic.totalQuestions - topic.doneQuestions;

    return Slidable(
      key: ValueKey(key),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: slidableActionExtentRatio,
        children: [
          SlidableAction(
            onPressed: (_) {
              _showEditDialog(context, topic);
            },
            backgroundColor: DashboardColors.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
      child: InkWell(
        onTap: selectionMode
            ? () => onToggleSelect(key)
            : () => _showDetailSheet(context, topic),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              if (selectionMode) ...[
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? DashboardColors.primary
                      : DashboardColors.textPrimary(isDark)
                          .withValues(alpha: 0.3),
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              // Topic name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.subtopic,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: DashboardColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : DashboardColors.primary.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _accuracyColor(accuracy),
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Remaining count
                    Text(
                      remaining > 0
                          ? '$remaining remaining'
                          : 'All done! 🎉',
                      style: TextStyle(
                        fontSize: 10,
                        color: remaining > 0
                            ? DashboardColors.textPrimary(isDark)
                                .withValues(alpha: 0.4)
                            : DashboardColors.success,
                        fontWeight: remaining == 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${topic.doneQuestions}/${topic.totalQuestions}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accuracyColor(accuracy)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$accuracy%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _accuracyColor(accuracy),
                      ),
                    ),
                  ),
                ],
              ),
              // Quick-mark + button
              if (!selectionMode && remaining > 0) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showQuickMark(context, topic),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DashboardColors.primary,
                          DashboardColors.primaryViolet,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: DashboardColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickMark(BuildContext context, UWorldTopic topic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickMarkSheet(app: app, topic: topic),
    );
  }

  Color _accuracyColor(int accuracy) {
    if (accuracy >= 80) return DashboardColors.success;
    if (accuracy >= 60) return DashboardColors.warning;
    return DashboardColors.danger;
  }

  void _showDetailSheet(BuildContext context, UWorldTopic topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A2E)
          : const Color(0xFFF5F3FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UWorldDetailSheet(app: app, topic: topic),
    );
  }

  void _showEditDialog(BuildContext context, UWorldTopic topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UWorldEditSheet(app: app, topic: topic),
    );
  }
}

// ── Stats header ──────────────────────────────────────────────

class _UWorldStatsHeader extends StatelessWidget {
  final int totalDone;
  final int totalQuestions;
  final int accuracy;
  final bool isDark;

  const _UWorldStatsHeader({
    required this.totalDone,
    required this.totalQuestions,
    required this.accuracy,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalQuestions > 0 ? totalDone / totalQuestions : 0.0;
    final textColor = DashboardColors.textPrimary(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DashboardColors.glassBorder(isDark),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Progress ring
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : DashboardColors.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accuracy >= 80
                                ? DashboardColors.success
                                : accuracy >= 60
                                    ? DashboardColors.warning
                                    : DashboardColors.danger,
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalDone / $totalQuestions Qs',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${totalQuestions - totalDone} remaining • $accuracy% accuracy',
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Accuracy badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (accuracy >= 80
                            ? DashboardColors.success
                            : accuracy >= 60
                                ? DashboardColors.warning
                                : DashboardColors.danger)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (accuracy >= 80
                              ? DashboardColors.success
                              : accuracy >= 60
                                  ? DashboardColors.warning
                                  : DashboardColors.danger)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$accuracy%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: accuracy >= 80
                          ? DashboardColors.success
                          : accuracy >= 60
                              ? DashboardColors.warning
                              : DashboardColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── UWorld Edit Sheet ─────────────────────────────────────────

class _UWorldEditSheet extends StatefulWidget {
  final AppProvider app;
  final UWorldTopic topic;
  const _UWorldEditSheet({required this.app, required this.topic});

  @override
  State<_UWorldEditSheet> createState() => _UWorldEditSheetState();
}

class _UWorldEditSheetState extends State<_UWorldEditSheet> {
  late TextEditingController _doneCtrl;
  late TextEditingController _correctCtrl;
  late TextEditingController _totalCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _doneCtrl =
        TextEditingController(text: '${widget.topic.doneQuestions}');
    _correctCtrl =
        TextEditingController(text: '${widget.topic.correctQuestions}');
    _totalCtrl =
        TextEditingController(text: '${widget.topic.totalQuestions}');
  }

  @override
  void dispose() {
    _doneCtrl.dispose();
    _correctCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final done = int.tryParse(_doneCtrl.text.trim()) ?? 0;
    final correct = int.tryParse(_correctCtrl.text.trim()) ?? 0;
    final total = int.tryParse(_totalCtrl.text.trim()) ?? 0;

    final clampedDone = done.clamp(0, total);
    final clampedCorrect = correct.clamp(0, clampedDone);

    await widget.app.updateUWorldProgress(
      widget.topic.id!,
      clampedDone,
      clampedCorrect,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.topic.subtopic,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.topic.system,
            style: TextStyle(
              fontSize: 13,
              color: DashboardColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _doneCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Questions Done',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _correctCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Correct',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _totalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Questions',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Quick Mark Sheet — compact stepper for marking questions
// ═══════════════════════════════════════════════════════════════

class _QuickMarkSheet extends StatefulWidget {
  final AppProvider app;
  final UWorldTopic topic;

  const _QuickMarkSheet({required this.app, required this.topic});

  @override
  State<_QuickMarkSheet> createState() => _QuickMarkSheetState();
}

class _QuickMarkSheetState extends State<_QuickMarkSheet> {
  late int _done;
  late int _correct;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _done = 0;
    _correct = 0;
  }

  int get _maxRemaining =>
      widget.topic.totalQuestions - widget.topic.doneQuestions;

  Future<void> _save() async {
    if (_done == 0) return;
    setState(() => _saving = true);
    await widget.app.updateUWorldProgress(
      widget.topic.id!,
      widget.topic.doneQuestions + _done,
      widget.topic.correctQuestions + _correct,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Quick Mark — ${widget.topic.subtopic}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.topic.doneQuestions}/${widget.topic.totalQuestions} done • $_maxRemaining remaining',
            style: TextStyle(
              fontSize: 12,
              color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          // Done stepper
          _buildStepper(
            label: 'Questions Done',
            value: _done,
            max: _maxRemaining,
            color: DashboardColors.primary,
            isDark: isDark,
            onChanged: (v) => setState(() {
              _done = v;
              if (_correct > _done) _correct = _done;
            }),
          ),
          const SizedBox(height: 12),
          // Correct stepper
          _buildStepper(
            label: 'Correct',
            value: _correct,
            max: _done,
            color: DashboardColors.success,
            isDark: isDark,
            onChanged: (v) => setState(() => _correct = v),
          ),
          const SizedBox(height: 8),
          // Wrong summary
          if (_done > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: DashboardColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded,
                      size: 14, color: DashboardColors.danger),
                  const SizedBox(width: 4),
                  Text(
                    '${_done - _correct} wrong',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _done > 0 && !_saving ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Add $_done question${_done != 1 ? 's' : ''}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required int max,
    required Color color,
    required bool isDark,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary(isDark),
            ),
          ),
        ),
        // - button
        InkWell(
          onTap: value > 0 ? () => onChanged(value - 1) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value > 0
                  ? color.withValues(alpha: 0.12)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.remove_rounded,
              size: 20,
              color: value > 0
                  ? color
                  : DashboardColors.textPrimary(isDark).withValues(alpha: 0.2),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // + button
        InkWell(
          onTap: value < max ? () => onChanged(value + 1) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value < max
                  ? color.withValues(alpha: 0.12)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: value < max
                  ? color
                  : DashboardColors.textPrimary(isDark).withValues(alpha: 0.2),
            ),
          ),
        ),
      ],
    );
  }
}
