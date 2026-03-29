import 'dart:async';

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/services/notification_service.dart';

class WakeupSnoozeOverlay extends StatefulWidget {
  final String dateKey;
  final VoidCallback onStartDay;
  final VoidCallback onDismiss;

  const WakeupSnoozeOverlay({
    super.key,
    required this.dateKey,
    required this.onStartDay,
    required this.onDismiss,
  });

  @override
  State<WakeupSnoozeOverlay> createState() => _WakeupSnoozeOverlayState();
}

class _WakeupSnoozeOverlayState extends State<WakeupSnoozeOverlay>
    with SingleTickerProviderStateMixin {
  static const List<int> _snoozeOptions = [5, 10, 15, 20];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _ticker;
  DateTime _currentTime = DateTime.now();
  int _secondsLeft = 60;
  bool _didDismiss = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _didDismiss) return;

      setState(() {
        _currentTime = DateTime.now();
        if (_secondsLeft > 0) {
          _secondsLeft -= 1;
        }
      });

      if (_secondsLeft == 0) {
        _handleDismiss();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _scheduleSnooze(int minutes) async {
    final when = DateTime.now().add(Duration(minutes: minutes));

    try {
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleAt(
        id: _notificationId(minutes),
        title: 'Wake-up Reminder',
        body: 'Snooze finished. Start your day now.',
        when: when,
        channelId: 'routine_reminder',
        channelName: 'Routine Reminders',
        intent: NotificationIntent.todayPlan(dateKey: widget.dateKey),
      );
    } catch (error) {
      debugPrint('Failed to schedule wake-up snooze: $error');
    }

    if (!mounted) return;
    _handleDismiss();
  }

  int _notificationId(int minutes) {
    final source = 'wake_snooze_${widget.dateKey}_$minutes';
    var hash = 0;
    for (final unit in source.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash;
  }

  void _handleDismiss() {
    if (_didDismiss) return;
    _didDismiss = true;
    _ticker?.cancel();
    widget.onDismiss();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = _secondsLeft / 60;

    return Material(
      color: cs.scrim.withValues(alpha: 0.84),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.24),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return AnimatedScale(
                          scale: _pulseAnimation.value,
                          duration: Duration.zero,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primaryContainer,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.alarm_rounded,
                          size: 46,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Good Morning! 🌅',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_currentTime),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onStartDay,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Start the Day Now'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        for (var i = 0; i < _snoozeOptions.length; i++) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _scheduleSnooze(_snoozeOptions[i]),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                foregroundColor: cs.onSurface,
                                side: BorderSide(color: cs.outlineVariant),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text('${_snoozeOptions[i]} min'),
                            ),
                          ),
                          if (i != _snoozeOptions.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Snooze will remind you again',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              strokeWidth: 7,
                              backgroundColor:
                                  cs.outlineVariant.withValues(alpha: 0.28),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cs.primary),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_secondsLeft',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'sec',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
