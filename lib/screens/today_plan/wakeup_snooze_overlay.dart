// =============================================================
// WakeupSnoozeOverlay — Full-screen overlay for starting the day
// Time-aware greeting, pulsing icon, snooze 5/10/15/20 min
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

  static const _snoozeOptions = [5, 10, 15, 20];

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

  // ── Time-aware greeting ────────────────────────────────────
  static _GreetingInfo _greeting(int hour) {
    if (hour >= 5 && hour < 12) {
      return const _GreetingInfo(
        text: 'Good Morning',
        icon: Icons.wb_sunny_rounded,
        from: Color(0xFFF59E0B),
        to: Color(0xFFFF6B35),
      );
    } else if (hour >= 12 && hour < 17) {
      return const _GreetingInfo(
        text: 'Good Afternoon',
        icon: Icons.wb_cloudy_rounded,
        from: Color(0xFF3B82F6),
        to: Color(0xFF06B6D4),
      );
    } else if (hour >= 17 && hour < 21) {
      return const _GreetingInfo(
        text: 'Good Evening',
        icon: Icons.nights_stay_rounded,
        from: Color(0xFF6366F1),
        to: Color(0xFF8B5CF6),
      );
    } else {
      return const _GreetingInfo(
        text: 'Working Late?',
        icon: Icons.bedtime_rounded,
        from: Color(0xFF1E1B4B),
        to: Color(0xFF312E81),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = TimeOfDay.now();
    final info = _greeting(now.hour);

    // Format scheduled time in 12hr
    final wt = widget.scheduledWakeTime;
    final h12 = wt.hour % 12 == 0 ? 12 : wt.hour % 12;
    final suffix = wt.hour < 12 ? 'AM' : 'PM';
    final scheduledLabel =
        '$h12:${wt.minute.toString().padLeft(2, '0')} $suffix';

    return Material(
      color: isDark
          ? const Color(0xFF0A0A14).withValues(alpha: 0.97)
          : Colors.white.withValues(alpha: 0.97),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Pulsing Icon ──────────────────────────────────
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [info.from, info.to],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: info.from.withValues(alpha: 0.4),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(info.icon, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),

            // ── Greeting ─────────────────────────────────────
            Text(
              info.text,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Scheduled start: $scheduledLabel',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),

            const Spacer(flex: 1),

            // ── Start Button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onStartNow();
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: const Text(
                    'Start the Day Now',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: info.from,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Snooze Row ───────────────────────────────────
            Text(
              'Snooze for',
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
                          horizontal: 16, vertical: 10),
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

class _GreetingInfo {
  final String text;
  final IconData icon;
  final Color from;
  final Color to;
  const _GreetingInfo({
    required this.text,
    required this.icon,
    required this.from,
    required this.to,
  });
}
