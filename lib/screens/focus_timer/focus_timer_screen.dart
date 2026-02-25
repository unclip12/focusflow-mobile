// =============================================================
// FocusTimerScreen â€” circular countdown timer with wakelock
// Shows active block name, session type, time remaining
// Start/Pause/Stop with WakelockPlus integration
// Animations: smooth arc via AnimatedBuilder, pulse when running.
// =============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'timer_controls.dart';
import 'session_complete_dialog.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  TimerState _state = TimerState.idle;

  // Session config
  int _totalSeconds = 25 * 60; // default 25 min
  final String _blockName = '';
  final String _subject = '';
  final String _sessionType = 'Focus';
  DateTime? _startedAt;

  // Preset options (minutes)
  static const _presets = [15, 25, 30, 45, 60, 90];
  int _selectedPreset = 25;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
    _controller.addStatusListener(_onAnimationStatus);

    // Pulse animation for the ring when timer is running
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    _pulseController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _state == TimerState.running) {
      // Timer completed naturally
      _onTimerComplete();
    }
  }

  void _onTimerComplete() {
    HapticsService.heavy();
    WakelockPlus.disable();
    _pulseController.stop();
    setState(() => _state = TimerState.idle);

    final elapsed = _totalSeconds;
    final elapsedMinutes = (elapsed / 60).ceil();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionCompleteDialog(
        durationMinutes: elapsedMinutes,
        blockName: _blockName,
        subject: _subject,
        startedAt: _startedAt ?? DateTime.now(),
      ),
    ).then((result) {
      _controller.reset();
    });
  }

  void _start() {
    HapticsService.medium();
    WakelockPlus.enable();
    _startedAt = DateTime.now();
    setState(() => _state = TimerState.running);
    _controller.forward();
    _pulseController.repeat();
  }

  void _pause() {
    HapticsService.light();
    WakelockPlus.disable();
    setState(() => _state = TimerState.paused);
    _controller.stop();
    _pulseController.stop();
  }

  void _resume() {
    HapticsService.light();
    WakelockPlus.enable();
    setState(() => _state = TimerState.running);
    _controller.forward();
    _pulseController.repeat();
  }

  void _stop() {
    HapticsService.medium();
    WakelockPlus.disable();
    _pulseController.stop();

    // Calculate elapsed time
    final elapsedFraction = _controller.value;
    final elapsedSeconds = (elapsedFraction * _totalSeconds).round();
    final elapsedMinutes = (elapsedSeconds / 60).ceil();

    setState(() => _state = TimerState.idle);

    if (elapsedMinutes >= 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SessionCompleteDialog(
          durationMinutes: elapsedMinutes,
          blockName: _blockName,
          subject: _subject,
          startedAt: _startedAt ?? DateTime.now(),
        ),
      ).then((_) {
        _controller.reset();
      });
    } else {
      _controller.reset();
    }
  }

  void _selectPreset(int minutes) {
    if (_state != TimerState.idle) return;
    setState(() {
      _selectedPreset = minutes;
      _totalSeconds = minutes * 60;
      _controller.duration = Duration(seconds: _totalSeconds);
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      screenName: 'Focus Timer',
      streakCount: 0,
      body: Column(
        children: [
          const SizedBox(height: 24),

          // â”€â”€ Session type chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _sessionType,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),

          // â”€â”€ Block name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_blockName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _blockName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],

          const Spacer(),

          // â”€â”€ Circular timer with pulse â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          AnimatedBuilder(
            animation: Listenable.merge([_controller, _pulseController]),
            builder: (context, child) {
              final remaining =
                  ((_totalSeconds * (1.0 - _controller.value))).round();
              final mins = remaining ~/ 60;
              final secs = remaining % 60;
              final pulseScale = _state == TimerState.running
                  ? _pulseAnim.value
                  : 1.0;

              return Transform.scale(
                scale: pulseScale,
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Track + progress arc (smooth via AnimatedBuilder)
                      CustomPaint(
                        size: const Size(260, 260),
                        painter: _CircularTimerPainter(
                          progress: _controller.value,
                          trackColor: cs.onSurface.withValues(alpha: 0.06),
                          progressColor: _state == TimerState.paused
                              ? const Color(0xFFF59E0B)
                              : cs.primary,
                          strokeWidth: 8,
                        ),
                      ),

                      // Glow effect when running
                      if (_state == TimerState.running)
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(
                                    alpha: 0.08 * pulseScale),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),

                      // Time display
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w300,
                              fontSize: 56,
                              letterSpacing: 2,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _state == TimerState.running
                                  ? 'Focus'
                                  : _state == TimerState.paused
                                      ? 'Paused'
                                      : 'Ready',
                              key: ValueKey(_state),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // â”€â”€ Preset chips (only when idle) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_state == TimerState.idle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _presets.map((m) {
                  final selected = m == _selectedPreset;
                  return GestureDetector(
                    onTap: () => _selectPreset(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? cs.primary.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${m}m',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),

          // â”€â”€ Controls â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          TimerControls(
            state: _state,
            onStart: _start,
            onPause: _pause,
            onResume: _resume,
            onStop: _stop,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// â”€â”€ Circular arc painter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc (counts down, so sweep = 2Ï€ * (1-progress))
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
