import 'package:flutter/material.dart';

class TimePickerSheet extends StatefulWidget {
  final Color headerColor;
  final String title;
  final String emoji;
  final String initialStartTime;
  final int initialDurationMinutes;

  const TimePickerSheet({
    super.key,
    required this.headerColor,
    required this.title,
    required this.emoji,
    required this.initialStartTime,
    required this.initialDurationMinutes,
  });

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

enum _TimePickerMode { standard, detailed }

enum _TimeMenuAction {
  changeDay,
  setTimezone,
  changeToAllDay,
  addToInbox,
  standardMode,
  detailedMode,
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  static const List<int> _durationOptions = <int>[
    1,
    15,
    30,
    45,
    60,
    90,
    120,
    180,
    240
  ];
  static const List<int> _quarterMinutes = <int>[0, 15, 30, 45];
  static const List<String> _periods = <String>['AM', 'PM'];
  static const int _minutesPerDay = 24 * 60;
  static const int _loopingCycles = 200;
  static const double _wheelItemExtent = 36;
  static const double _wheelHeight = _wheelItemExtent * 5;

  static const Color _kBodyColor = Color(0xFF171717);
  static const Color _kCardColor = Color(0xFF262629);
  static const Color _kAccentColor = Color(0xFFFF8E88);
  static const Color _kMutedTextColor = Color(0xFFAAAAB1);

  late final FixedExtentScrollController _startHourController;
  late final FixedExtentScrollController _startMinuteController;
  late final FixedExtentScrollController _startPeriodController;
  late final FixedExtentScrollController _endHourController;
  late final FixedExtentScrollController _endMinuteController;
  late final FixedExtentScrollController _endPeriodController;

  late _TimePickerMode _pickerMode;
  late int _selectedDuration;

  late int _startHourItem;
  late int _startMinuteItem;
  late int _startPeriodItem;
  late int _endHourItem;
  late int _endMinuteItem;
  late int _endPeriodItem;

  bool _syncingControllers = false;

  List<int> get _minuteValues => _pickerMode == _TimePickerMode.standard
      ? _quarterMinutes
      : List<int>.generate(60, (index) => index, growable: false);

  int get _startMinutes => _composeMinutes(
        hourIndex: _selectedIndex(_startHourItem, 12),
        minuteIndex: _selectedIndex(_startMinuteItem, _minuteValues.length),
        periodIndex: _selectedIndex(_startPeriodItem, _periods.length),
      );

  int get _endMinutes => _composeMinutes(
        hourIndex: _selectedIndex(_endHourItem, 12),
        minuteIndex: _selectedIndex(_endMinuteItem, _minuteValues.length),
        periodIndex: _selectedIndex(_endPeriodItem, _periods.length),
      );

  @override
  void initState() {
    super.initState();
    _pickerMode = _TimePickerMode.standard;

    final initialStartMinutes = _snapMinutesToMode(
      _minutesFromHhmm(widget.initialStartTime),
      _pickerMode,
    );
    final initialDuration =
        widget.initialDurationMinutes > 0 ? widget.initialDurationMinutes : 60;
    final initialEndMinutes = _snapMinutesToMode(
      initialStartMinutes + initialDuration,
      _pickerMode,
    );

    _selectedDuration =
        _durationBetween(initialStartMinutes, initialEndMinutes);
    _setStartFromMinutes(initialStartMinutes);
    _setEndFromMinutes(initialEndMinutes);

    _startHourController =
        FixedExtentScrollController(initialItem: _startHourItem);
    _startMinuteController =
        FixedExtentScrollController(initialItem: _startMinuteItem);
    _startPeriodController =
        FixedExtentScrollController(initialItem: _startPeriodItem);
    _endHourController = FixedExtentScrollController(initialItem: _endHourItem);
    _endMinuteController =
        FixedExtentScrollController(initialItem: _endMinuteItem);
    _endPeriodController =
        FixedExtentScrollController(initialItem: _endPeriodItem);
  }

  @override
  void dispose() {
    _startHourController.dispose();
    _startMinuteController.dispose();
    _startPeriodController.dispose();
    _endHourController.dispose();
    _endMinuteController.dispose();
    _endPeriodController.dispose();
    super.dispose();
  }

  int _minutesFromHhmm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      return 0;
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return _normalizeMinutes(hour * 60 + minute);
  }

  int _normalizeMinutes(int value) {
    return ((value % _minutesPerDay) + _minutesPerDay) % _minutesPerDay;
  }

  int _selectedIndex(int rawItem, int itemCount) {
    return ((rawItem % itemCount) + itemCount) % itemCount;
  }

  int _initialLoopItem(int logicalIndex, int itemCount) {
    return (itemCount * (_loopingCycles ~/ 2)) + logicalIndex;
  }

  int _nearestLoopItem({
    required int logicalIndex,
    required int itemCount,
    required int currentRawItem,
  }) {
    var target = ((currentRawItem ~/ itemCount) * itemCount) + logicalIndex;
    final lower = target - itemCount;
    final upper = target + itemCount;

    if ((lower - currentRawItem).abs() < (target - currentRawItem).abs()) {
      target = lower;
    }
    if ((upper - currentRawItem).abs() < (target - currentRawItem).abs()) {
      target = upper;
    }

    final minRaw = itemCount * 10;
    final maxRaw = (itemCount * (_loopingCycles - 10)) + logicalIndex;
    return target.clamp(minRaw, maxRaw);
  }

  int _snapMinutesToMode(int totalMinutes, _TimePickerMode mode) {
    final normalized = _normalizeMinutes(totalMinutes);
    if (mode == _TimePickerMode.detailed) {
      return normalized;
    }
    return (((normalized + 7) ~/ 15) * 15) % _minutesPerDay;
  }

  _WheelSelection _selectionForMinutes(int totalMinutes) {
    final snappedMinutes = _snapMinutesToMode(totalMinutes, _pickerMode);
    final hour24 = (snappedMinutes ~/ 60) % 24;
    final minute = snappedMinutes % 60;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;

    return _WheelSelection(
      hourIndex: hour12 - 1,
      minuteIndex:
          _minuteValues.indexOf(minute).clamp(0, _minuteValues.length - 1),
      periodIndex: hour24 < 12 ? 0 : 1,
    );
  }

  void _setStartFromMinutes(int totalMinutes, {bool preserveLoop = false}) {
    final selection = _selectionForMinutes(totalMinutes);
    _startHourItem = preserveLoop
        ? _nearestLoopItem(
            logicalIndex: selection.hourIndex,
            itemCount: 12,
            currentRawItem: _startHourItem,
          )
        : _initialLoopItem(selection.hourIndex, 12);
    _startMinuteItem = preserveLoop
        ? _nearestLoopItem(
            logicalIndex: selection.minuteIndex,
            itemCount: _minuteValues.length,
            currentRawItem: _startMinuteItem,
          )
        : _initialLoopItem(selection.minuteIndex, _minuteValues.length);
    _startPeriodItem = preserveLoop
        ? _nearestLoopItem(
            logicalIndex: selection.periodIndex,
            itemCount: _periods.length,
            currentRawItem: _startPeriodItem,
          )
        : _initialLoopItem(selection.periodIndex, _periods.length);
  }

  void _setEndFromMinutes(int totalMinutes, {bool preserveLoop = false}) {
    final selection = _selectionForMinutes(totalMinutes);
    _endHourItem = preserveLoop
        ? _nearestLoopItem(
            logicalIndex: selection.hourIndex,
            itemCount: 12,
            currentRawItem: _endHourItem,
          )
        : _initialLoopItem(selection.hourIndex, 12);
    _endMinuteItem = preserveLoop
        ? _nearestLoopItem(
            logicalIndex: selection.minuteIndex,
            itemCount: _minuteValues.length,
            currentRawItem: _endMinuteItem,
          )
        : _initialLoopItem(selection.minuteIndex, _minuteValues.length);
    _endPeriodItem = preserveLoop
        ? _nearestLoopItem(
            logicalIndex: selection.periodIndex,
            itemCount: _periods.length,
            currentRawItem: _endPeriodItem,
          )
        : _initialLoopItem(selection.periodIndex, _periods.length);
  }

  int _composeMinutes({
    required int hourIndex,
    required int minuteIndex,
    required int periodIndex,
  }) {
    final hour12 = hourIndex + 1;
    final minute = _minuteValues[minuteIndex];
    final hour24 = (hour12 % 12) + (periodIndex == 1 ? 12 : 0);
    return _normalizeMinutes((hour24 * 60) + minute);
  }

  int _durationBetween(int startMinutes, int endMinutes) {
    final diff = (endMinutes - startMinutes) % _minutesPerDay;
    return diff == 0 ? _minutesPerDay : diff;
  }

  String _hhmmFromMinutes(int minutes) {
    final normalized = _normalizeMinutes(minutes);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatClockTime(int minutes, {bool includePeriod = true}) {
    final normalized = _normalizeMinutes(minutes);
    final hour24 = (normalized ~/ 60) % 24;
    final minute = normalized % 60;
    final suffix = hour24 < 12 ? 'AM' : 'PM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final base = '$hour12:${minute.toString().padLeft(2, '0')}';
    return includePeriod ? '$base $suffix' : base;
  }

  String _formatRangeSummary() {
    final startPeriod = _startMinutes < 12 * 60 ? 'AM' : 'PM';
    final endPeriod = _endMinutes < 12 * 60 ? 'AM' : 'PM';
    final startLabel = _formatClockTime(
      _startMinutes,
      includePeriod: startPeriod != endPeriod,
    );
    final endLabel = _formatClockTime(_endMinutes);
    return '$startLabel - $endLabel (${_formatDurationLabel(_selectedDuration)})';
  }

  String _formatDurationLabel(int minutes) {
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hr' : '$hours hr';
    }
    if (minutes > 60) {
      final hours = minutes ~/ 60;
      final remainder = minutes % 60;
      final hourLabel = hours == 1 ? '1 hr' : '$hours hr';
      return '$hourLabel $remainder min';
    }
    return minutes == 1 ? '1 min' : '$minutes min';
  }

  String _durationChipLabel(int minutes) {
    switch (minutes) {
      case 1:
        return '1 min';
      case 15:
      case 30:
      case 45:
        return '$minutes';
      case 60:
        return '1h';
      case 90:
        return '1.5h';
      case 120:
        return '2h';
      case 180:
        return '3h';
      case 240:
        return '4h';
      default:
        return '$minutes min';
    }
  }

  void _syncControllers({bool start = true, bool end = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncingControllers = true;
      if (start) {
        _jumpController(_startHourController, _startHourItem);
        _jumpController(_startMinuteController, _startMinuteItem);
        _jumpController(_startPeriodController, _startPeriodItem);
      }
      if (end) {
        _jumpController(_endHourController, _endHourItem);
        _jumpController(_endMinuteController, _endMinuteItem);
        _jumpController(_endPeriodController, _endPeriodItem);
      }
      _syncingControllers = false;
    });
  }

  void _jumpController(FixedExtentScrollController controller, int targetItem) {
    if (!controller.hasClients) {
      return;
    }
    controller.jumpToItem(targetItem);
  }

  void _updateStartSelection({
    int? hourItem,
    int? minuteItem,
    int? periodItem,
  }) {
    if (_syncingControllers) {
      return;
    }
    setState(() {
      if (hourItem != null) {
        _startHourItem = hourItem;
      }
      if (minuteItem != null) {
        _startMinuteItem = minuteItem;
      }
      if (periodItem != null) {
        _startPeriodItem = periodItem;
      }
      _setEndFromMinutes(_startMinutes + _selectedDuration, preserveLoop: true);
    });
    _syncControllers(end: true, start: false);
  }

  void _updateEndSelection({
    int? hourItem,
    int? minuteItem,
    int? periodItem,
  }) {
    if (_syncingControllers) {
      return;
    }
    setState(() {
      if (hourItem != null) {
        _endHourItem = hourItem;
      }
      if (minuteItem != null) {
        _endMinuteItem = minuteItem;
      }
      if (periodItem != null) {
        _endPeriodItem = periodItem;
      }
      _selectedDuration = _durationBetween(_startMinutes, _endMinutes);
    });
  }

  void _selectDuration(int minutes) {
    setState(() {
      _selectedDuration = minutes;
      _setEndFromMinutes(_startMinutes + minutes, preserveLoop: true);
    });
    _syncControllers(end: true, start: false);
  }

  void _setPickerMode(_TimePickerMode mode) {
    if (_pickerMode == mode) {
      return;
    }

    final currentStart = _startMinutes;
    final currentEnd = _endMinutes;

    setState(() {
      _pickerMode = mode;
      final snappedStart = _snapMinutesToMode(currentStart, mode);
      final snappedEnd = _snapMinutesToMode(currentEnd, mode);
      _setStartFromMinutes(snappedStart, preserveLoop: true);
      _setEndFromMinutes(snappedEnd, preserveLoop: true);
      _selectedDuration = _durationBetween(snappedStart, snappedEnd);
    });

    _syncControllers();
  }

  void _handleMenuAction(_TimeMenuAction action) {
    switch (action) {
      case _TimeMenuAction.standardMode:
        _setPickerMode(_TimePickerMode.standard);
        return;
      case _TimeMenuAction.detailedMode:
        _setPickerMode(_TimePickerMode.detailed);
        return;
      case _TimeMenuAction.changeDay:
        _showMenuPlaceholder('Change Day is not wired in this sheet yet.');
        return;
      case _TimeMenuAction.setTimezone:
        _showMenuPlaceholder('Set Timezone is not wired in this sheet yet.');
        return;
      case _TimeMenuAction.changeToAllDay:
        _showMenuPlaceholder(
            'Change to All-Day is not wired in this sheet yet.');
        return;
      case _TimeMenuAction.addToInbox:
        _showMenuPlaceholder('Add to Inbox is not wired in this sheet yet.');
        return;
    }
  }

  void _showMenuPlaceholder(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF303034),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 16;

    return FractionallySizedBox(
      heightFactor: 0.94,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: Material(
          color: _kBodyColor,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  color: widget.headerColor,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _HeaderCircleButton(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          const SizedBox(width: 44),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4B4B4F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _formatRangeSummary(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          label: 'Time',
                          trailing: PopupMenuButton<_TimeMenuAction>(
                            onSelected: _handleMenuAction,
                            color: const Color(0xFF2A2A2D),
                            position: PopupMenuPosition.under,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            icon: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.more_horiz_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: _TimeMenuAction.changeDay,
                                child: Text('Change Day'),
                              ),
                              const PopupMenuItem(
                                value: _TimeMenuAction.setTimezone,
                                child: Text('Set Timezone'),
                              ),
                              const PopupMenuItem(
                                value: _TimeMenuAction.changeToAllDay,
                                child: Text('Change to All-Day'),
                              ),
                              const PopupMenuItem(
                                value: _TimeMenuAction.addToInbox,
                                child: Text('Add to Inbox'),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<_TimeMenuAction>(
                                enabled: false,
                                child: Row(
                                  children: [
                                    Text(
                                      'Time Picker',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              CheckedPopupMenuItem<_TimeMenuAction>(
                                value: _TimeMenuAction.standardMode,
                                checked:
                                    _pickerMode == _TimePickerMode.standard,
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text('Standard'),
                                ),
                              ),
                              CheckedPopupMenuItem<_TimeMenuAction>(
                                value: _TimeMenuAction.detailedMode,
                                checked:
                                    _pickerMode == _TimePickerMode.detailed,
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text('Detailed'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: _kCardColor,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Start time',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Text(
                                      'End time',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _TimeWheelGroup(
                                      hourWheel: _WheelColumn(
                                        controller: _startHourController,
                                        itemCount: 12 * _loopingCycles,
                                        selectedRawItem: _startHourItem,
                                        labelBuilder: (rawIndex) =>
                                            '${_selectedIndex(rawIndex, 12) + 1}',
                                        onSelectedItemChanged: (rawIndex) =>
                                            _updateStartSelection(
                                                hourItem: rawIndex),
                                      ),
                                      minuteWheel: _WheelColumn(
                                        controller: _startMinuteController,
                                        itemCount: _minuteValues.length *
                                            _loopingCycles,
                                        selectedRawItem: _startMinuteItem,
                                        labelBuilder: (rawIndex) =>
                                            _minuteValues[_selectedIndex(
                                                    rawIndex,
                                                    _minuteValues.length)]
                                                .toString()
                                                .padLeft(2, '0'),
                                        onSelectedItemChanged: (rawIndex) =>
                                            _updateStartSelection(
                                                minuteItem: rawIndex),
                                      ),
                                      periodWheel: _WheelColumn(
                                        controller: _startPeriodController,
                                        itemCount:
                                            _periods.length * _loopingCycles,
                                        selectedRawItem: _startPeriodItem,
                                        labelBuilder: (rawIndex) => _periods[
                                            _selectedIndex(
                                                rawIndex, _periods.length)],
                                        onSelectedItemChanged: (rawIndex) =>
                                            _updateStartSelection(
                                                periodItem: rawIndex),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                    height: _wheelHeight,
                                    child: Center(
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _TimeWheelGroup(
                                      hourWheel: _WheelColumn(
                                        controller: _endHourController,
                                        itemCount: 12 * _loopingCycles,
                                        selectedRawItem: _endHourItem,
                                        labelBuilder: (rawIndex) =>
                                            '${_selectedIndex(rawIndex, 12) + 1}',
                                        onSelectedItemChanged: (rawIndex) =>
                                            _updateEndSelection(
                                                hourItem: rawIndex),
                                      ),
                                      minuteWheel: _WheelColumn(
                                        controller: _endMinuteController,
                                        itemCount: _minuteValues.length *
                                            _loopingCycles,
                                        selectedRawItem: _endMinuteItem,
                                        labelBuilder: (rawIndex) =>
                                            _minuteValues[_selectedIndex(
                                                    rawIndex,
                                                    _minuteValues.length)]
                                                .toString()
                                                .padLeft(2, '0'),
                                        onSelectedItemChanged: (rawIndex) =>
                                            _updateEndSelection(
                                                minuteItem: rawIndex),
                                      ),
                                      periodWheel: _WheelColumn(
                                        controller: _endPeriodController,
                                        itemCount:
                                            _periods.length * _loopingCycles,
                                        selectedRawItem: _endPeriodItem,
                                        labelBuilder: (rawIndex) => _periods[
                                            _selectedIndex(
                                                rawIndex, _periods.length)],
                                        onSelectedItemChanged: (rawIndex) =>
                                            _updateEndSelection(
                                                periodItem: rawIndex),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        const _SectionHeader(label: 'Duration'),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _durationOptions.map((duration) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _DurationChip(
                                  label: _durationChipLabel(duration),
                                  selected: duration == _selectedDuration,
                                  onTap: () => _selectDuration(duration),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _kAccentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(<String, dynamic>{
                                'startTime': _hhmmFromMinutes(_startMinutes),
                                'durationMinutes': _selectedDuration,
                              });
                            },
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelSelection {
  final int hourIndex;
  final int minuteIndex;
  final int periodIndex;

  const _WheelSelection({
    required this.hourIndex,
    required this.minuteIndex,
    required this.periodIndex,
  });
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionHeader({
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TimeWheelGroup extends StatelessWidget {
  final Widget hourWheel;
  final Widget minuteWheel;
  final Widget periodWheel;

  const _TimeWheelGroup({
    required this.hourWheel,
    required this.minuteWheel,
    required this.periodWheel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _TimePickerSheetState._wheelHeight,
      child: Row(
        children: [
          Expanded(child: hourWheel),
          const SizedBox(width: 4),
          Expanded(child: minuteWheel),
          const SizedBox(width: 4),
          Expanded(child: periodWheel),
        ],
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedRawItem;
  final String Function(int rawIndex) labelBuilder;
  final ValueChanged<int> onSelectedItemChanged;

  const _WheelColumn({
    required this.controller,
    required this.itemCount,
    required this.selectedRawItem,
    required this.labelBuilder,
    required this.onSelectedItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _TimePickerSheetState._wheelHeight,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _TimePickerSheetState._wheelItemExtent,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.65,
        perspective: 0.003,
        squeeze: 1.08,
        onSelectedItemChanged: onSelectedItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, rawIndex) {
            final isSelected = rawIndex == selectedRawItem;
            return Center(
              child: Text(
                labelBuilder(rawIndex),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.34),
                  fontSize: isSelected ? 21 : 17,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: isSelected ? 0.1 : 0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? _TimePickerSheetState._kAccentColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : _TimePickerSheetState._kMutedTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
