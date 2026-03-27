// =============================================================
// WakeupSnoozeOverlay — Full-screen overlay for starting the day
// Shows "Start the Day Now" + snooze buttons (5/10/15/20 min)
// =============================================================

import 'package:flutter/material.dart';

class WakeupSnoozeOverlay extends StatefulWidget {
  final VoidCallback onStartNow;
  final void Function(int minutes) onSnooze;
  final TimeOfDay scheduledWakeTime;

  const WakeupSnoozeOverlay({
    super.key,
    required this.onStartNow,
    required this.onSnooze,
    required this.scheduledWakeTime,
  });

  @override
  State<WakeupSnoozeOverlay> createState() => _WakeupSnoozeOverlayState();
}

class _WakeupSnoozeOverlayState extends State<WakeupSnoozeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  static const _snoozeOptions = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? const Color(0xFF0A0A14).withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Icon
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.wb_sunny_rounded,
                    size: 44, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Good Morning',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scheduled wake time: ${widget.scheduledWakeTime.format(context)}',
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(flex: 1),
            // Start button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onStartNow();
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text('Start the Day Now',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Snooze buttons
            Text(
              'Snooze',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _snoozeOptions.map((min) {
                  return OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSnooze(min);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: cs.onSurface.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    child: Text(
                      '${min}m',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
