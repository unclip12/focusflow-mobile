import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/constants.dart';

const Color _kStudyScreenBackground = Color(0xFF0D0D0D);
const Color _kStudyScreenAccent = Color(0xFFE8837A);
const Color _kStudyScreenTrack = Color(0xFF343436);
const Color _kStudyScreenCard = Color(0xFF1A1A1C);
const Color _kStudyScreenSurface = Color(0xFF232326);
const Color _kStudyScreenMuted = Color(0xFF9A9AA0);

class StudySessionScreen extends StatefulWidget {
  final Block block;

  const StudySessionScreen({
    super.key,
    required this.block,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  bool get _isRunning => _stopwatch.isRunning;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleSession() {
    if (_isRunning) {
      _endSession();
      return;
    }
    _startSession();
  }

  void _startSession() {
    if (_stopwatch.elapsedMilliseconds > 0) {
      _stopwatch
        ..stop()
        ..reset();
    }

    _ticker?.cancel();
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    setState(() {});
  }

  void _endSession() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    final elapsed = _formatElapsed(_stopwatch.elapsed);

    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Session completed in $elapsed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kStudyScreenSurface,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final blocks =
        app.getDayPlan(widget.block.date)?.blocks ?? <Block>[widget.block];
    final totalBlocks = blocks.isEmpty ? 1 : blocks.length;
    final completedBlocks =
        blocks.where((block) => block.status == BlockStatus.done).length;
    final progress = totalBlocks == 0 ? 0.0 : completedBlocks / totalBlocks;

    return Scaffold(
      extendBody: true,
      backgroundColor: _kStudyScreenBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionHeader(
                title: '${_blockEmoji(widget.block)} ${widget.block.title}',
                timeRange:
                    '${_formatPlannedTime(context, widget.block.plannedStartTime)} – ${_formatPlannedTime(context, widget.block.plannedEndTime)}',
                elapsed: _formatElapsed(_stopwatch.elapsed),
                isRunning: _isRunning,
                onBack: () => Navigator.of(context).pop(),
                onToggle: _toggleSession,
              ),
              const SizedBox(height: 24),
              _ProgressSection(
                progress: progress,
                completedBlocks: completedBlocks,
                totalBlocks: totalBlocks,
              ),
              const SizedBox(height: 28),
              const _PlaceholderSection(
                title: '📄 FA Pages',
                addLabel: '＋ Add FA Page',
                items: [
                  _PlaceholderCardData(
                    title: 'FA Page 1',
                    emoji: '📄',
                    badge: 'Sketchy',
                  ),
                  _PlaceholderCardData(
                    title: 'FA Page 2',
                    emoji: '📄',
                    badge: 'Sketchy',
                  ),
                  _PlaceholderCardData(
                    title: 'FA Page 3',
                    emoji: '📄',
                    badge: 'Sketchy',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _PlaceholderSection(
                title: '🧬 Sketchy Micro',
                addLabel: '＋ Add Topic',
                items: [
                  _PlaceholderCardData(
                    title: 'Micro Topic 1',
                    emoji: '🧬',
                    badge: 'Sketchy',
                  ),
                  _PlaceholderCardData(
                    title: 'Micro Topic 2',
                    emoji: '🧬',
                    badge: 'Sketchy',
                  ),
                  _PlaceholderCardData(
                    title: 'Micro Topic 3',
                    emoji: '🧬',
                    badge: 'Sketchy',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _PlaceholderSection(
                title: '🎥 Videos',
                addLabel: '＋ Add Video',
                items: [
                  _PlaceholderCardData(
                    title: 'Video 1',
                    showVideoPreview: true,
                  ),
                  _PlaceholderCardData(
                    title: 'Video 2',
                    showVideoPreview: true,
                  ),
                  _PlaceholderCardData(
                    title: 'Video 3',
                    showVideoPreview: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _toggleSession,
            style: FilledButton.styleFrom(
              backgroundColor: _kStudyScreenAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isRunning ? 'End Session' : 'Start Session',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final String title;
  final String timeRange;
  final String elapsed;
  final bool isRunning;
  final VoidCallback onBack;
  final VoidCallback onToggle;

  const _SessionHeader({
    required this.title,
    required this.timeRange,
    required this.elapsed,
    required this.isRunning,
    required this.onBack,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 86),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                timeRange,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kStudyScreenMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            splashRadius: 22,
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                elapsed,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              _HeaderToggleButton(
                label: isRunning ? 'End' : 'Start',
                onPressed: onToggle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderToggleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _HeaderToggleButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _kStudyScreenAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final int completedBlocks;
  final int totalBlocks;

  const _ProgressSection({
    required this.progress,
    required this.completedBlocks,
    required this.totalBlocks,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: _kStudyScreenTrack,
            valueColor:
                const AlwaysStoppedAnimation<Color>(_kStudyScreenAccent),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$percent% Complete  •  $completedBlocks/$totalBlocks blocks',
          style: const TextStyle(
            color: _kStudyScreenMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  final String title;
  final List<_PlaceholderCardData> items;
  final String addLabel;

  const _PlaceholderSection({
    required this.title,
    required this.items,
    required this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in items) ...[
                _PlaceholderCard(data: item),
                const SizedBox(width: 12),
              ],
              _AddPlaceholderCard(label: addLabel),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceholderCardData {
  final String title;
  final String? emoji;
  final String? badge;
  final bool showVideoPreview;

  const _PlaceholderCardData({
    required this.title,
    this.emoji,
    this.badge,
    this.showVideoPreview = false,
  });
}

class _PlaceholderCard extends StatelessWidget {
  final _PlaceholderCardData data;

  const _PlaceholderCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kStudyScreenCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: data.showVideoPreview
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: _kStudyScreenSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.emoji ?? '',
                  style: const TextStyle(fontSize: 28),
                ),
                const Spacer(),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (data.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _kStudyScreenAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      data.badge!,
                      style: const TextStyle(
                        color: _kStudyScreenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AddPlaceholderCard extends StatelessWidget {
  final String label;

  const _AddPlaceholderCard({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 180,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: _kStudyScreenAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

String _blockEmoji(Block block) {
  final title = block.title.toLowerCase();
  if (title.contains('lecture') || block.type == BlockType.video) return '🎥';
  if (title.contains('anki') || block.type == BlockType.anki) return '🧠';
  if (title.contains('qbank') || block.type == BlockType.qbank) return '📝';
  if (title.contains('revision')) return '🧬';
  return '📚';
}

String _formatPlannedTime(BuildContext context, String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;

  final totalMinutes =
      (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  final time = TimeOfDay(
    hour: totalMinutes ~/ 60,
    minute: totalMinutes % 60,
  );

  return MaterialLocalizations.of(context).formatTimeOfDay(
    time,
    alwaysUse24HourFormat: false,
  );
}

String _formatElapsed(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
