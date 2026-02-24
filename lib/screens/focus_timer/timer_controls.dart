// =============================================================
// TimerControls — animated Start / Pause / Stop buttons
// =============================================================

import 'package:flutter/material.dart';

enum TimerState { idle, running, paused }

class TimerControls extends StatelessWidget {
  final TimerState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const TimerControls({
    super.key,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Stop (visible when running or paused) ───────────────
        if (state != TimerState.idle)
          _AnimatedButton(
            icon: Icons.stop_rounded,
            label: 'Stop',
            color: const Color(0xFFEF4444),
            onTap: onStop,
          ),

        if (state != TimerState.idle) const SizedBox(width: 20),

        // ── Start / Pause / Resume ──────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: _buildPrimaryButton(),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    switch (state) {
      case TimerState.idle:
        return _AnimatedButton(
          key: const ValueKey('start'),
          icon: Icons.play_arrow_rounded,
          label: 'Start',
          color: const Color(0xFF10B981),
          onTap: onStart,
          large: true,
        );
      case TimerState.running:
        return _AnimatedButton(
          key: const ValueKey('pause'),
          icon: Icons.pause_rounded,
          label: 'Pause',
          color: const Color(0xFFF59E0B),
          onTap: onPause,
          large: true,
        );
      case TimerState.paused:
        return _AnimatedButton(
          key: const ValueKey('resume'),
          icon: Icons.play_arrow_rounded,
          label: 'Resume',
          color: const Color(0xFF10B981),
          onTap: onResume,
          large: true,
        );
    }
  }
}

// ── Single animated button ──────────────────────────────────────
class _AnimatedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  const _AnimatedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 56.0;
    final iconSize = large ? 32.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
