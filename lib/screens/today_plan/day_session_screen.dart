// =============================================================
// DaySessionScreen - Active day session view
// Shows: current task + timer, next task preview, progress bar
// Done Early / Skip / Pull Up buttons, cascades via scheduler
// =============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/day_session.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class DaySessionScreen extends StatefulWidget {
  final String dateKey;
  final DaySession session;

  const DaySessionScreen({
    super.key,
    required this.dateKey,
    required this.session,
  });

  @override
  State<DaySessionScreen> createState() => _DaySessionScreenState();
}

class _DaySessionScreenState extends State<DaySessionScreen> {
  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _cardColor = Color(0xFF1C1C1E);
  static const _accentColor = Color(0xFFE8837A);
  static const _primaryTextColor = Colors.white;
  static const _secondaryTextColor = Color(0xFF9A9AA0);

  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  List<Block> _sortedBlocks(List<Block> blocks) {
    final sorted = List<Block>.from(blocks);
    sorted.sort((a, b) {
      final startCompare =
          _toMinutes(a.plannedStartTime).compareTo(_toMinutes(b.plannedStartTime));
      if (startCompare != 0) return startCompare;
      return a.title.compareTo(b.title);
    });
    return sorted;
  }

  bool _isCompleted(Block block) {
    // The shared enum still uses `done` as its completed terminal state.
    return block.status == BlockStatus.done;
  }

  bool _isActionable(Block block) {
    return !_isCompleted(block) && block.status != BlockStatus.skipped;
  }

  int _completedCount(List<Block> blocks) {
    return blocks.where(_isCompleted).length;
  }

  bool _allBlocksCompleted(List<Block> blocks) {
    return blocks.isNotEmpty && _completedCount(blocks) == blocks.length;
  }

  Block? _primaryBlock(List<Block> blocks) {
    final actionableBlocks = _sortedBlocks(blocks).where(_isActionable).toList();
    if (actionableBlocks.isEmpty) return null;

    final currentId = widget.session.currentBlockId;
    if (currentId != null) {
      for (final block in actionableBlocks) {
        if (block.id == currentId) return block;
      }
    }

    for (final block in actionableBlocks) {
      if (block.status == BlockStatus.inProgress) return block;
    }

    return actionableBlocks.first;
  }

  Block? _nextBlock(List<Block> blocks, {Block? after}) {
    final actionableBlocks = _sortedBlocks(blocks).where(_isActionable).toList();
    if (actionableBlocks.isEmpty) return null;
    if (after == null) return actionableBlocks.first;

    final currentIdx = actionableBlocks.indexWhere((b) => b.id == after.id);
    if (currentIdx < 0) return actionableBlocks.first;
    if (currentIdx + 1 >= actionableBlocks.length) return null;
    return actionableBlocks[currentIdx + 1];
  }

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  DateTime? _parseClockTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
    if (match != null) {
      final hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour < 24 &&
          minute >= 0 &&
          minute < 60) {
        return DateTime(2000, 1, 1, hour, minute);
      }
    }

    return DateTime.tryParse(trimmed);
  }

  String _formatTimeDisplay(String value) {
    final parsed = _parseClockTime(value);
    if (parsed == null) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? '--' : trimmed;
    }
    return DateFormat('h:mm a').format(parsed);
  }

  String _formatBlockTimeRange(Block block) {
    final start = _parseClockTime(block.plannedStartTime);
    final end = _parseClockTime(block.plannedEndTime);
    final startLabel = _formatTimeDisplay(block.plannedStartTime);

    if (start == null) {
      return '$startLabel – ${_formatTimeDisplay(block.plannedEndTime)}';
    }

    final resolvedEnd =
        end ?? start.add(Duration(minutes: block.plannedDurationMinutes));
    return '${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(resolvedEnd)}';
  }

  double _progress(List<Block> blocks) {
    if (blocks.isEmpty) return 0;
    return _completedCount(blocks) / blocks.length;
  }

  bool _isNowBlock(Block block) {
    return block.status == BlockStatus.inProgress ||
        widget.session.currentBlockId == block.id;
  }

  void _completeCurrent(AppProvider app, Block block) {
    app.completeDayPlanBlock(
      widget.dateKey,
      block.id,
      startedAt: widget.session.startedAt,
      completedAt: DateTime.now(),
      autoAdvanceFlow: true,
    );
    app.rescheduleFromNow(widget.dateKey);
    setState(() => _elapsedSeconds = 0);
  }

  void _skipCurrent(AppProvider app, Block block) {
    final plan = app.getDayPlan(widget.dateKey);
    if (plan == null) return;
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx < 0) return;
    blocks[idx] = blocks[idx].copyWith(status: BlockStatus.skipped);
    app.upsertDayPlan(plan.copyWith(blocks: blocks));
    app.rescheduleFromNow(widget.dateKey);
    setState(() => _elapsedSeconds = 0);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final plan = app.getDayPlan(widget.dateKey);
    final blocks = plan?.blocks ?? const <Block>[];
    final primaryBlock = _primaryBlock(blocks);
    final next = _nextBlock(blocks, after: primaryBlock);
    final progress = _progress(blocks);
    final completedCount = _completedCount(blocks);
    final allBlocksCompleted = _allBlocksCompleted(blocks);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Day Session',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _primaryTextColor,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              app.endDaySession(widget.dateKey);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.stop_rounded, size: 18, color: Colors.red),
            label: const Text(
              'End',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(_accentColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).round()}% Complete',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _secondaryTextColor,
                  ),
                ),
                Text(
                  '$completedCount/${blocks.length} blocks',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (primaryBlock != null) ...[
              Text(
                _isNowBlock(primaryBlock) ? 'NOW' : 'NEXT UP',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _accentColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      primaryBlock.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatBlockTimeRange(primaryBlock),
                      style: const TextStyle(
                        fontSize: 14,
                        color: _secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatElapsed(_elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _skipCurrent(app, primaryBlock),
                            icon: const Icon(Icons.skip_next_rounded, size: 18),
                            label: const Text('Skip'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryTextColor,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () => _completeCurrent(app, primaryBlock),
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text(
                              'Done Early',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 40),
              Icon(
                allBlocksCompleted
                    ? Icons.check_circle_outline_rounded
                    : Icons.celebration_rounded,
                size: 56,
                color: _accentColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                allBlocksCompleted
                    ? 'All blocks completed!'
                    : "You're all done for today! 🎉",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                allBlocksCompleted
                    ? 'Great work today'
                    : 'No incomplete blocks remain.',
                style: const TextStyle(
                  fontSize: 14,
                  color: _secondaryTextColor,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'UP NEXT',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _secondaryTextColor,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (next != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.navigate_next_rounded,
                        color: _accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatBlockTimeRange(next),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: const Text(
                  "You're all done for today! 🎉",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
