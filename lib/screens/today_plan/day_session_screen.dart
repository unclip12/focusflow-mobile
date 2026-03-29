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
import 'package:focusflow_mobile/screens/today_plan/routine_runner_screen.dart';
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
  static const _accentColor = Color(0xFFE8837A);

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
    _elapsedSeconds = _sessionElapsedSeconds(widget.session.startedAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds = _sessionElapsedSeconds(widget.session.startedAt);
      });
    });
  }

  int _sessionElapsedSeconds(DateTime sessionStartedAt) {
    final elapsed = DateTime.now().difference(sessionStartedAt).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
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
    return block.status == BlockStatus.done;
  }

  bool _isActionable(Block block) {
    return !_isCompleted(block) && block.status != BlockStatus.skipped;
  }

  bool _isRetroactiveBlock(Block block) {
    final title = block.title.toLowerCase();
    final description = (block.description ?? '').toLowerCase();
    return title.contains('retroactive') || description.contains('retroactive');
  }

  List<Block> _sessionBlocks(List<Block> allBlocks) {
    return allBlocks.where((block) => !_isRetroactiveBlock(block)).toList();
  }

  int _completedCount(List<Block> blocks) {
    return blocks.where(_isCompleted).length;
  }

  bool _allBlocksCompleted(List<Block> blocks) {
    return blocks.isNotEmpty && _completedCount(blocks) == blocks.length;
  }

  Block? _primaryBlock(List<Block> blocks, {String? currentBlockId}) {
    final actionableBlocks = _sortedBlocks(blocks).where(_isActionable).toList();
    if (actionableBlocks.isEmpty) return null;

    if (currentBlockId != null) {
      for (final block in actionableBlocks) {
        if (block.id == currentBlockId) return block;
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
      return '$startLabel - ${_formatTimeDisplay(block.plannedEndTime)}';
    }

    final resolvedEnd =
        end ?? start.add(Duration(minutes: block.plannedDurationMinutes));
    return '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(resolvedEnd)}';
  }

  double _progress(List<Block> blocks) {
    if (blocks.isEmpty) return 0;
    return _completedCount(blocks) / blocks.length;
  }

  bool _isNowBlock(Block block, {String? currentBlockId}) {
    return block.status == BlockStatus.inProgress || currentBlockId == block.id;
  }

  String _blockEmoji(Block block) {
    switch (block.type) {
      case BlockType.video:
        return '\u{1F3AC}';
      case BlockType.revisionFa:
      case BlockType.fmgeRevision:
        return '\u{1F504}';
      case BlockType.anki:
        return '\u{1F9E0}';
      case BlockType.qbank:
        return '\u{270D}';
      case BlockType.studySession:
      case BlockType.mixed:
        return '\u{1F4DA}';
      case BlockType.breakBlock:
        return '\u{2615}';
      case BlockType.other:
        return '\u{1F4CC}';
    }
  }

  Future<void> _completeCurrent(
    AppProvider app,
    Block block,
    List<Block> sessionBlocks,
  ) async {
    final plan = app.getDayPlan(widget.dateKey);
    if (plan == null) return;

    final nextBlock = _nextBlock(sessionBlocks, after: block);
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx < 0) return;

    final now = DateTime.now();
    final actualStart = DateTime.tryParse(block.actualStartTime ?? '') ??
        widget.session.startedAt;
    final actualDurationMinutes = now.difference(actualStart).inMinutes;

    blocks[idx] = blocks[idx].copyWith(
      actualStartTime: block.actualStartTime ?? actualStart.toIso8601String(),
      actualEndTime: now.toIso8601String(),
      actualDurationMinutes: actualDurationMinutes < 0 ? 0 : actualDurationMinutes,
      status: BlockStatus.done,
    );

    await app.upsertDayPlan(plan.copyWith(blocks: blocks));
    await app.rescheduleFromNow(widget.dateKey);
    if (nextBlock != null) {
      app.setCurrentBlock(widget.dateKey, nextBlock.id);
    }
  }

  Future<void> _skipCurrent(
    AppProvider app,
    Block block,
    List<Block> sessionBlocks,
  ) async {
    final plan = app.getDayPlan(widget.dateKey);
    if (plan == null) return;

    final nextBlock = _nextBlock(sessionBlocks, after: block);
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx < 0) return;

    blocks[idx] = blocks[idx].copyWith(status: BlockStatus.skipped);
    await app.upsertDayPlan(plan.copyWith(blocks: blocks));
    await app.rescheduleFromNow(widget.dateKey);
    if (nextBlock != null) {
      app.setCurrentBlock(widget.dateKey, nextBlock.id);
    }
  }

  Future<void> _startRoutineBlock(
    AppProvider app,
    Block block,
  ) async {
    final routine = app.getRoutineForBlock(block);
    if (routine == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineRunnerScreen(
          routine: routine,
          dateKey: widget.dateKey,
          sourceBlockId: block.id,
        ),
      ),
    );

    if (!mounted) return;
    final nextBlockId = app.getFirstActionableBlockId(widget.dateKey);
    if (nextBlockId != null) {
      app.setCurrentBlock(widget.dateKey, nextBlockId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final activeSession = app.getActiveDaySession(widget.dateKey) ?? widget.session;
    final plan = app.getDayPlan(widget.dateKey);
    final allBlocks = plan?.blocks ?? const <Block>[];
    final sessionBlocks = _sessionBlocks(allBlocks);
    final primaryBlock = _primaryBlock(
      sessionBlocks,
      currentBlockId: activeSession.currentBlockId,
    );
    final next = _nextBlock(sessionBlocks, after: primaryBlock);
    final progress = _progress(sessionBlocks);
    final completedCount = _completedCount(sessionBlocks);
    final allBlocksCompleted = _allBlocksCompleted(sessionBlocks);
    final primaryRoutine =
        primaryBlock == null ? null : app.getRoutineForBlock(primaryBlock);
    final primaryIsRoutine = primaryRoutine != null;
    final theme = Theme.of(context);
    final primaryTextColor =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final secondaryTextColor = primaryTextColor.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Day Session',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
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
                backgroundColor: primaryTextColor.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(_accentColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).round()}% Complete',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
                Text(
                  '$completedCount/${sessionBlocks.length} blocks',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (primaryBlock != null) ...[
              Text(
                _isNowBlock(
                  primaryBlock,
                  currentBlockId: activeSession.currentBlockId,
                )
                    ? 'NOW'
                    : 'NEXT UP',
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
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_blockEmoji(primaryBlock)} ${primaryBlock.title}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatBlockTimeRange(primaryBlock),
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
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
                    if (primaryIsRoutine)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _skipCurrent(app, primaryBlock, sessionBlocks);
                              },
                              icon: const Icon(Icons.skip_next_rounded, size: 18),
                              label: const Text('Skip'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryTextColor,
                                side: BorderSide(
                                  color: primaryTextColor.withValues(alpha: 0.14),
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
                              onPressed: () async {
                                await _startRoutineBlock(app, primaryBlock);
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: const Text(
                                'Start Routine',
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
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _skipCurrent(app, primaryBlock, sessionBlocks);
                              },
                              icon: const Icon(Icons.skip_next_rounded, size: 18),
                              label: const Text('Skip'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryTextColor,
                                side: BorderSide(
                                  color: primaryTextColor.withValues(alpha: 0.14),
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
                              onPressed: () async {
                                await _completeCurrent(app, primaryBlock, sessionBlocks);
                              },
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
                          if (_elapsedSeconds >=
                              primaryBlock.plannedDurationMinutes * 60) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await _completeCurrent(
                                    app,
                                    primaryBlock,
                                    sessionBlocks,
                                  );
                                },
                                icon: const Icon(Icons.task_alt_rounded, size: 20),
                                label: const Text(
                                  'Done',
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
                    : "You're all done for today!",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                allBlocksCompleted
                    ? 'Great work today'
                    : 'No incomplete blocks remain.',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
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
                  color: _accentColor,
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
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryTextColor.withValues(alpha: 0.06),
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatBlockTimeRange(next),
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
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
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryTextColor.withValues(alpha: 0.06),
                  ),
                ),
                child: Text(
                  "You're all done for today!",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
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
