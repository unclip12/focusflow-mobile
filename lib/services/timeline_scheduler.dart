// =============================================================
// TimelineScheduler — pure Dart scheduling engine
// Separates events (fixed) from tasks (movable), cascades tasks
// sequentially, and splits tasks around event overlaps.
// =============================================================

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class TimelineScheduler {
  TimelineScheduler._();

  /// Parse "HH:mm" to minutes since midnight.
  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  /// Format minutes since midnight back to "HH:mm".
  static String _fromMinutes(int mins) {
    final h = (mins ~/ 60).clamp(0, 23);
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Schedule all blocks for a day.
  ///
  /// [blocks] — all blocks for the day (events + tasks)
  /// [startTime] — when to start scheduling movable tasks from
  ///
  /// Events (isEvent == true, or prayer blocks) keep their planned times.
  /// Tasks are scheduled sequentially from [startTime], cascading one after
  /// another. If a task overlaps an event, it is split:
  ///   Part 1 runs from cursor to event start.
  ///   Part 2 runs from event end for the remaining duration.
  /// Completed/skipped tasks are left in place but do not occupy schedule time.
  static List<Block> schedule({
    required List<Block> blocks,
    required DateTime startTime,
  }) {
    // Separate into events and tasks
    final events = <Block>[];
    final tasks = <Block>[];
    final completedOrSkipped = <Block>[];

    for (final b in blocks) {
      if (b.status == BlockStatus.done || b.status == BlockStatus.skipped) {
        completedOrSkipped.add(b);
      } else if (b.isEvent || b.id.startsWith('prayer_')) {
        events.add(b);
      } else {
        tasks.add(b);
      }
    }

    // Sort events by start time
    events.sort(
        (a, b) => _toMinutes(a.plannedStartTime).compareTo(_toMinutes(b.plannedStartTime)));

    // Build list of occupied time ranges from events
    final eventRanges = events
        .map((e) => (
              start: _toMinutes(e.plannedStartTime),
              end: _toMinutes(e.plannedEndTime),
              block: e,
            ))
        .toList();

    // Schedule tasks sequentially
    int cursor = startTime.hour * 60 + startTime.minute;
    final scheduled = <Block>[];

    for (final task in tasks) {
      final duration = task.remainingDurationMinutes;
      if (duration <= 0) {
        // Zero-duration tasks just place at cursor
        scheduled.add(task.copyWith(
          plannedStartTime: _fromMinutes(cursor),
          plannedEndTime: _fromMinutes(cursor),
        ));
        continue;
      }

      int remaining = duration;
      int partIndex = 0;
      int totalParts = 1;

      // Check how many events we'll overlap — pre-calculate total parts
      int tempCursor = cursor;
      int tempRemaining = remaining;
      int overlaps = 0;
      while (tempRemaining > 0) {
        final overlapping = _findNextOverlap(eventRanges, tempCursor, tempCursor + tempRemaining);
        if (overlapping == null) {
          break;
        }
        final beforeEvent = overlapping.start - tempCursor;
        if (beforeEvent > 0) {
          overlaps++;
        }
        tempRemaining -= beforeEvent;
        tempCursor = overlapping.end;
        if (tempRemaining > 0) {
          overlaps++;
        }
        // In simplified model, count at most 1 split (2 parts)
        break;
      }
      totalParts = overlaps > 0 ? 2 : 1;

      // Now actually schedule
      while (remaining > 0) {
        // Skip past any event that starts at or before cursor
        cursor = _skipPastEvents(eventRanges, cursor);

        final taskEnd = cursor + remaining;
        final overlapping = _findNextOverlap(eventRanges, cursor, taskEnd);

        if (overlapping == null) {
          // No overlap — place entire remaining duration
          partIndex++;
          final isPartOfSplit = totalParts > 1;
          scheduled.add(task.copyWith(
            id: isPartOfSplit ? '${task.id}_p$partIndex' : task.id,
            plannedStartTime: _fromMinutes(cursor),
            plannedEndTime: _fromMinutes(cursor + remaining),
            plannedDurationMinutes: remaining,
            remainingDurationMinutes: remaining,
            splitGroupId: isPartOfSplit ? task.id : null,
            splitPartIndex: isPartOfSplit ? partIndex : null,
            splitTotalParts: isPartOfSplit ? totalParts : null,
          ));
          cursor += remaining;
          remaining = 0;
        } else {
          // Overlap detected — split
          final beforeEvent = overlapping.start - cursor;
          if (beforeEvent > 0) {
            partIndex++;
            scheduled.add(task.copyWith(
              id: '${task.id}_p$partIndex',
              plannedStartTime: _fromMinutes(cursor),
              plannedEndTime: _fromMinutes(cursor + beforeEvent),
              plannedDurationMinutes: beforeEvent,
              remainingDurationMinutes: beforeEvent,
              splitGroupId: task.id,
              splitPartIndex: partIndex,
              splitTotalParts: totalParts,
            ));
            remaining -= beforeEvent;
          }
          // Jump cursor past the event
          cursor = overlapping.end;
        }
      }
    }

    // Merge everything: completed/skipped + events + scheduled tasks
    final result = <Block>[
      ...completedOrSkipped,
      ...events,
      ...scheduled,
    ];

    // Sort by planned start time
    result.sort(
        (a, b) => _toMinutes(a.plannedStartTime).compareTo(_toMinutes(b.plannedStartTime)));

    // Re-index
    for (int i = 0; i < result.length; i++) {
      result[i] = result[i].copyWith(index: i);
    }

    return result;
  }

  /// Skip cursor past any event that the cursor is currently inside.
  static int _skipPastEvents(
    List<({int start, int end, Block block})> events,
    int cursor,
  ) {
    for (final e in events) {
      if (cursor >= e.start && cursor < e.end) {
        cursor = e.end;
      }
    }
    return cursor;
  }

  /// Find the next event that overlaps with the range [start, end).
  static ({int start, int end, Block block})? _findNextOverlap(
    List<({int start, int end, Block block})> events,
    int start,
    int end,
  ) {
    for (final e in events) {
      // Event overlaps if it starts after range start but before range end
      if (e.start > start && e.start < end) {
        return e;
      }
    }
    return null;
  }
}
