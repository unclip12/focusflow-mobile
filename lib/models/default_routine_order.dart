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
  fajrPrayer,
  zuhrPrayer,
  asrPrayer,
  maghribPrayer,
  ishaPrayer,
  custom;

  String get value {
    switch (this) {
      case ActivityType.morningRoutine:  return 'MORNING_ROUTINE';
      case ActivityType.study:           return 'STUDY';
      case ActivityType.lunch:           return 'LUNCH';
      case ActivityType.shopping:        return 'SHOPPING';
      case ActivityType.eveningRoutine:  return 'EVENING_ROUTINE';
      case ActivityType.sleep:           return 'SLEEP';
      case ActivityType.fajrPrayer:      return 'FAJR_PRAYER';
      case ActivityType.zuhrPrayer:      return 'ZUHR_PRAYER';
      case ActivityType.asrPrayer:       return 'ASR_PRAYER';
      case ActivityType.maghribPrayer:   return 'MAGHRIB_PRAYER';
      case ActivityType.ishaPrayer:      return 'ISHA_PRAYER';
      case ActivityType.custom:          return 'CUSTOM';
    }
  }

  String get label {
    switch (this) {
      case ActivityType.morningRoutine:  return 'Morning Routine';
      case ActivityType.study:           return 'Study';
      case ActivityType.lunch:           return 'Lunch';
      case ActivityType.shopping:        return 'Shopping';
      case ActivityType.eveningRoutine:  return 'Evening Routine';
      case ActivityType.sleep:           return 'Sleep';
      case ActivityType.fajrPrayer:      return 'Fajr 🕌';
      case ActivityType.zuhrPrayer:      return 'Zuhr 🕌';
      case ActivityType.asrPrayer:       return 'Asr 🕌';
      case ActivityType.maghribPrayer:   return 'Maghrib 🕌';
      case ActivityType.ishaPrayer:      return 'Isha 🕌';
      case ActivityType.custom:          return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.morningRoutine:  return '🌅';
      case ActivityType.study:           return '📚';
      case ActivityType.lunch:           return '🍽️';
      case ActivityType.shopping:        return '🛒';
      case ActivityType.eveningRoutine:  return '🌙';
      case ActivityType.sleep:           return '😴';
      case ActivityType.fajrPrayer:      return '🕌';
      case ActivityType.zuhrPrayer:      return '🕌';
      case ActivityType.asrPrayer:       return '🕌';
      case ActivityType.maghribPrayer:   return '🕌';
      case ActivityType.ishaPrayer:      return '🕌';
      case ActivityType.custom:          return '⚡';
    }
  }

  bool get isPrayer => this == fajrPrayer || this == zuhrPrayer ||
      this == asrPrayer || this == maghribPrayer || this == ishaPrayer;

  static ActivityType fromString(String s) {
    switch (s) {
      case 'MORNING_ROUTINE':  return ActivityType.morningRoutine;
      case 'STUDY':            return ActivityType.study;
      case 'LUNCH':            return ActivityType.lunch;
      case 'SHOPPING':         return ActivityType.shopping;
      case 'EVENING_ROUTINE':  return ActivityType.eveningRoutine;
      case 'SLEEP':            return ActivityType.sleep;
      case 'FAJR_PRAYER':      return ActivityType.fajrPrayer;
      case 'ZUHR_PRAYER':      return ActivityType.zuhrPrayer;
      case 'ASR_PRAYER':       return ActivityType.asrPrayer;
      case 'MAGHRIB_PRAYER':   return ActivityType.maghribPrayer;
      case 'ISHA_PRAYER':      return ActivityType.ishaPrayer;
      default:                 return ActivityType.custom;
    }
  }
}

class DefaultActivity {
  final String id;
  final ActivityType type;
  final String? routineId; // linked routine (for routine types)
  final String? label;     // custom label override
  final List<String> linkedTaskIds; // linked to-do / study-plan items
  final int sortOrder;

  const DefaultActivity({
    required this.id,
    required this.type,
    this.routineId,
    this.label,
    this.linkedTaskIds = const [],
    required this.sortOrder,
  });

  String get displayLabel => label ?? type.label;
  String get displayIcon => type.icon;

  factory DefaultActivity.fromJson(Map<String, dynamic> j) => DefaultActivity(
        id: j['id'] ?? '',
        type: ActivityType.fromString(j['type'] ?? 'CUSTOM'),
        routineId: j['routineId'],
        label: j['label'],
        linkedTaskIds: j['linkedTaskIds'] != null
            ? List<String>.from(j['linkedTaskIds'])
            : [],
        sortOrder: j['sortOrder'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        if (routineId != null) 'routineId': routineId,
        if (label != null) 'label': label,
        'linkedTaskIds': linkedTaskIds,
        'sortOrder': sortOrder,
      };

  DefaultActivity copyWith({
    String? id,
    ActivityType? type,
    String? routineId,
    String? label,
    List<String>? linkedTaskIds,
    int? sortOrder,
  }) =>
      DefaultActivity(
        id: id ?? this.id,
        type: type ?? this.type,
        routineId: routineId ?? this.routineId,
        label: label ?? this.label,
        linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
