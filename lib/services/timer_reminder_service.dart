import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:focusflow_mobile/models/app_settings.dart';
import 'package:focusflow_mobile/services/notification_service.dart';

class ActiveTimerCueContext {
  final String sessionKey;
  final String taskKey;
  final String currentLabel;
  final String? nextLabel;
  final int totalDurationSeconds;
  final int elapsedSeconds;
  final bool isPaused;
  final NotificationIntent? intent;

  const ActiveTimerCueContext({
    required this.sessionKey,
    required this.taskKey,
    required this.currentLabel,
    this.nextLabel,
    required this.totalDurationSeconds,
    required this.elapsedSeconds,
    this.isPaused = false,
    this.intent,
  });
}

class TimerReminderService {
  TimerReminderService._();

  static final TimerReminderService instance = TimerReminderService._();

  static const String _milestoneTwentyPercent = 'twenty_percent';
  static const String _milestoneFiveMinutes = 'five_minutes';
  static const String _milestoneOneMinute = 'one_minute';

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final Map<String, Set<String>> _firedMilestones = <String, Set<String>>{};

  Future<void> processActiveTimerCue({
    required TimerReminderConfig config,
    required ActiveTimerCueContext context,
  }) async {
    if (context.isPaused || context.totalDurationSeconds <= 0) {
      return;
    }

    final cueKey = '${context.sessionKey}::${context.taskKey}';
    final fired = _firedMilestones.putIfAbsent(cueKey, () => <String>{});
    final remainingSeconds =
        math.max(0, context.totalDurationSeconds - context.elapsedSeconds);
    final dueMilestones = _resolveDueMilestones(
      totalDurationSeconds: context.totalDurationSeconds,
      remainingSeconds: remainingSeconds,
      alreadyFired: fired,
    );
    if (dueMilestones.isEmpty) return;

    fired.addAll(dueMilestones);
    final primaryMilestone = _pickPrimaryMilestone(dueMilestones);
    final message = _buildCueMessage(
      milestone: primaryMilestone,
      currentLabel: context.currentLabel,
      nextLabel: context.nextLabel,
    );

    await NotificationService.instance.showImmediate(
      id: ('${cueKey}_$primaryMilestone').hashCode & 0x7fffffff,
      title: _buildNotificationTitle(
        milestone: primaryMilestone,
        currentLabel: context.currentLabel,
      ),
      body: message,
      channelId: 'focus_timer',
      channelName: 'Focus Timer',
      intent: context.intent,
    );

    if (config.playCueSounds) {
      await _playCue(primaryMilestone);
    }
    if (config.speakReminders) {
      await _speak(message);
    }
  }

  void clearSession(String sessionKey) {
    _firedMilestones.removeWhere((key, _) => key.startsWith('$sessionKey::'));
  }

  List<String> _resolveDueMilestones({
    required int totalDurationSeconds,
    required int remainingSeconds,
    required Set<String> alreadyFired,
  }) {
    final due = <String>[];
    final twentyPercentSeconds =
        (totalDurationSeconds * 0.2).round().clamp(1, totalDurationSeconds);
    final thresholds = <String, int>{
      _milestoneTwentyPercent: twentyPercentSeconds,
      _milestoneFiveMinutes: 5 * 60,
      _milestoneOneMinute: 60,
    };

    thresholds.forEach((milestone, threshold) {
      final isImpossible = threshold >= totalDurationSeconds;
      if (isImpossible || alreadyFired.contains(milestone)) {
        return;
      }
      if (remainingSeconds <= threshold) {
        due.add(milestone);
      }
    });

    return due;
  }

  String _pickPrimaryMilestone(List<String> milestones) {
    if (milestones.contains(_milestoneOneMinute)) {
      return _milestoneOneMinute;
    }
    if (milestones.contains(_milestoneFiveMinutes)) {
      return _milestoneFiveMinutes;
    }
    return _milestoneTwentyPercent;
  }

  String _buildCueMessage({
    required String milestone,
    required String currentLabel,
    String? nextLabel,
  }) {
    final nextSentence = (milestone == _milestoneFiveMinutes ||
            milestone == _milestoneOneMinute) &&
        nextLabel != null &&
        nextLabel.trim().isNotEmpty
        ? ' Next: ${nextLabel.trim()}.'
        : '';

    switch (milestone) {
      case _milestoneOneMinute:
        return 'One minute left for $currentLabel.$nextSentence';
      case _milestoneFiveMinutes:
        return 'Five minutes left for $currentLabel.$nextSentence';
      case _milestoneTwentyPercent:
      default:
        return 'Twenty percent left for $currentLabel.';
    }
  }

  String _buildNotificationTitle({
    required String milestone,
    required String currentLabel,
  }) {
    switch (milestone) {
      case _milestoneOneMinute:
        return '$currentLabel ends in 1 minute';
      case _milestoneFiveMinutes:
        return '$currentLabel ends in 5 minutes';
      case _milestoneTwentyPercent:
      default:
        return '$currentLabel is nearing the end';
    }
  }

  Future<void> _playCue(String milestone) async {
    final assetPath = switch (milestone) {
      _milestoneOneMinute => 'audio/timer_urgent.wav',
      _milestoneFiveMinutes => 'audio/timer_warning.wav',
      _ => 'audio/timer_notice.wav',
    };

    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (error, stackTrace) {
      debugPrint('Timer cue playback failed: $error\n$stackTrace');
    }
  }

  Future<void> _speak(String message) async {
    try {
      await _tts.stop();
      await _tts.awaitSpeakCompletion(false);
      await _tts.speak(message);
    } catch (error, stackTrace) {
      debugPrint('Timer cue TTS failed: $error\n$stackTrace');
    }
  }
}
