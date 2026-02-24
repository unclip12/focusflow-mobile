// =============================================================
// SessionScreen — Full-screen focus timer with motivational quotes
// Receives a Block (and its index/date) via GoRouter extra.
// =============================================================

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/screens/session/session_complete_sheet.dart';

/// Data bundle passed to the session screen via GoRouter extra.
class SessionArgs {
  final Block block;
  final int blockIndex;
  final String dayPlanDate; // YYYY-MM-DD

  const SessionArgs({
    required this.block,
    required this.blockIndex,
    required this.dayPlanDate,
  });
}

class SessionScreen extends StatefulWidget {
  final SessionArgs args;
  const SessionScreen({super.key, required this.args});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  // ── Timer state ──────────────────────────────────────────────
  late final DateTime _startedAt;
  int _elapsedSeconds = 0;
  Timer? _tickTimer;
  bool _isPaused = false;

  // ── Quote rotation ──────────────────────────────────────────
  Timer? _quoteTimer;
  late String _currentQuote;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _currentQuote = kFocusQuotes[_rng.nextInt(kFocusQuotes.length)];
    _startTimers();
  }

  void _startTimers() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() => _elapsedSeconds++);
      }
    });
    _quoteTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(
          () => _currentQuote = kFocusQuotes[_rng.nextInt(kFocusQuotes.length)]);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _endSession() {
    _tickTimer?.cancel();
    _quoteTimer?.cancel();

    showSessionCompleteSheet(
      context,
      block: widget.args.block,
      blockIndex: widget.args.blockIndex,
      dayPlanDate: widget.args.dayPlanDate,
      startedAt: _startedAt,
      endedAt: DateTime.now(),
      elapsedSeconds: _elapsedSeconds,
    );
  }

  // ── Formatting helpers ──────────────────────────────────────
  String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final block = widget.args.block;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    onPressed: () => _showExitConfirm(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            size: 8,
                            color: _isPaused
                                ? Colors.orange
                                : const Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          _isPaused ? 'Paused' : 'Studying',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // balance for close btn
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ── Task name ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                block.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 32),

            // ── Large timer ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 24),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _formatElapsed(_elapsedSeconds),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 64,
                  color: cs.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Started at label ───────────────────────────────
            Text(
              'Started at ${DateFormat('h:mm a').format(_startedAt)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),

            const Spacer(flex: 2),

            // ── Control buttons ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  // Pause / Resume
                  Expanded(
                    child: _ActionButton(
                      icon: _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: _isPaused ? 'Resume' : 'Pause',
                      color: cs.onSurface.withValues(alpha: 0.7),
                      backgroundColor:
                          cs.onSurface.withValues(alpha: 0.06),
                      onTap: _togglePause,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // End Session
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.stop_rounded,
                      label: 'End Session',
                      color: Colors.white,
                      backgroundColor: cs.error,
                      onTap: _endSession,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // ── Motivational quote ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  '"$_currentQuote"',
                  key: ValueKey(_currentQuote),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withValues(alpha: 0.4),
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showExitConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End session?'),
        content: const Text(
            'Your progress will be lost if you exit without saving.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Studying'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ACTION BUTTON
// ══════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
