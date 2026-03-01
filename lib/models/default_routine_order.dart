// =============================================================
// DefaultActivity — configurable chain of activities for
// the "Default" button in the activity selector.
// =============================================================

enum ActivityType {
  morningRoutine,
  study,
  lunch,
  shopping,
  eveningRoutine,
  sleep,
  custom;

  String get value {
    switch (this) {
      case ActivityType.morningRoutine: return 'MORNING_ROUTINE';
      case ActivityType.study:         return 'STUDY';
      case ActivityType.lunch:         return 'LUNCH';
      case ActivityType.shopping:      return 'SHOPPING';
      case ActivityType.eveningRoutine: return 'EVENING_ROUTINE';
      case ActivityType.sleep:         return 'SLEEP';
      case ActivityType.custom:        return 'CUSTOM';
    }
  }

  String get label {
    switch (this) {
      case ActivityType.morningRoutine: return 'Morning Routine';
      case ActivityType.study:         return 'Study';
      case ActivityType.lunch:         return 'Lunch';
      case ActivityType.shopping:      return 'Shopping';
      case ActivityType.eveningRoutine: return 'Evening Routine';
      case ActivityType.sleep:         return 'Sleep';
      case ActivityType.custom:        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.morningRoutine: return '🌅';
      case ActivityType.study:         return '📚';
      case ActivityType.lunch:         return '🍽️';
      case ActivityType.shopping:      return '🛒';
      case ActivityType.eveningRoutine: return '🌙';
      case ActivityType.sleep:         return '😴';
      case ActivityType.custom:        return '⚡';
    }
  }

  static ActivityType fromString(String s) {
    switch (s) {
      case 'MORNING_ROUTINE': return ActivityType.morningRoutine;
      case 'STUDY':           return ActivityType.study;
      case 'LUNCH':           return ActivityType.lunch;
      case 'SHOPPING':        return ActivityType.shopping;
      case 'EVENING_ROUTINE': return ActivityType.eveningRoutine;
      case 'SLEEP':           return ActivityType.sleep;
      default:                return ActivityType.custom;
    }
  }
}

class DefaultActivity {
  final String id;
  final ActivityType type;
  final String? routineId; // linked routine (for routine types)
  final String? label;     // custom label override
  final int sortOrder;

  const DefaultActivity({
    required this.id,
    required this.type,
    this.routineId,
    this.label,
    required this.sortOrder,
  });

  String get displayLabel => label ?? type.label;
  String get displayIcon => type.icon;

  factory DefaultActivity.fromJson(Map<String, dynamic> j) => DefaultActivity(
        id: j['id'] ?? '',
        type: ActivityType.fromString(j['type'] ?? 'CUSTOM'),
        routineId: j['routineId'],
        label: j['label'],
        sortOrder: j['sortOrder'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        if (routineId != null) 'routineId': routineId,
        if (label != null) 'label': label,
        'sortOrder': sortOrder,
      };

  DefaultActivity copyWith({
    String? id,
    ActivityType? type,
    String? routineId,
    String? label,
    int? sortOrder,
  }) =>
      DefaultActivity(
        id: id ?? this.id,
        type: type ?? this.type,
        routineId: routineId ?? this.routineId,
        label: label ?? this.label,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
