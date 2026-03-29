import 'package:flutter/material.dart';

class AlertRepeatSheet extends StatefulWidget {
  final int initialAlertOffset;
  final String initialAlertType;
  final String initialRecurrenceType;
  final List<int> initialRecurrenceDays;

  const AlertRepeatSheet({
    super.key,
    required this.initialAlertOffset,
    required this.initialAlertType,
    required this.initialRecurrenceType,
    required this.initialRecurrenceDays,
  });

  @override
  State<AlertRepeatSheet> createState() => _AlertRepeatSheetState();
}

class _AlertRepeatSheetState extends State<AlertRepeatSheet> {
  static const _bodyColor = Color(0xFF1C1C1E);
  static const _cardColor = Color(0xFF252528);
  static const _surfaceColor = Color(0xFF2E2E33);
  static const _accentColor = Color(0xFFFF8E88);
  static const _mutedTextColor = Color(0xFF9B9BA1);
  static const _borderColor = Color(0xFF35353A);
  static const _weekdayToggleLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _alertOptions = <_SelectionOption<int>>[
    _SelectionOption(label: 'None', value: -1),
    _SelectionOption(label: 'At time of task', value: 0),
    _SelectionOption(label: '5 minutes before', value: -5),
    _SelectionOption(label: '10 minutes before', value: -10),
    _SelectionOption(label: '15 minutes before', value: -15),
    _SelectionOption(label: '30 minutes before', value: -30),
    _SelectionOption(label: '1 hour before', value: -60),
  ];
  static const _repeatOptions = <_SelectionOption<String>>[
    _SelectionOption(label: 'None', value: 'none'),
    _SelectionOption(label: 'Every day', value: 'daily'),
    _SelectionOption(label: 'Every week', value: 'weekly'),
    _SelectionOption(label: 'Every month', value: 'monthly'),
    _SelectionOption(label: 'Every year', value: 'yearly'),
  ];
  static const _alertTypeOptions = <_SelectionOption<String>>[
    _SelectionOption(label: 'Nudge', value: 'nudge'),
    _SelectionOption(label: 'Notification', value: 'notification'),
    _SelectionOption(label: 'Alarm', value: 'alarm'),
  ];

  late int _alertOffsetMinutes;
  late String _alertType;
  late String _recurrenceType;
  late List<int> _recurrenceDays;

  @override
  void initState() {
    super.initState();
    _alertOffsetMinutes = _normalizeAlertOffset(widget.initialAlertOffset);
    _alertType = _normalizeAlertType(widget.initialAlertType);
    _recurrenceType = _normalizeRecurrenceType(widget.initialRecurrenceType);
    _recurrenceDays = _normalizeRecurrenceDays(widget.initialRecurrenceDays);
  }

  int _normalizeAlertOffset(int value) {
    for (final option in _alertOptions) {
      if (option.value == value) return value;
    }
    return -1;
  }

  String _normalizeAlertType(String value) {
    for (final option in _alertTypeOptions) {
      if (option.value == value) return value;
    }
    return 'nudge';
  }

  String _normalizeRecurrenceType(String value) {
    for (final option in _repeatOptions) {
      if (option.value == value) return value;
    }
    return 'none';
  }

  List<int> _normalizeRecurrenceDays(List<int> values) {
    final normalized = values
        .where((value) => value >= 0 && value <= 6)
        .toSet()
        .toList()
      ..sort();
    return normalized;
  }

  void _toggleRecurrenceDay(int dayIndex) {
    setState(() {
      if (_recurrenceDays.contains(dayIndex)) {
        _recurrenceDays.remove(dayIndex);
      } else {
        _recurrenceDays = [..._recurrenceDays, dayIndex]..sort();
      }
    });
  }

  void _handleDone() {
    final recurrenceDays =
        _recurrenceType == 'weekly' ? ([..._recurrenceDays]..sort()) : <int>[];
    Navigator.of(context).pop(<String, dynamic>{
      'alertOffsetMinutes': _alertOffsetMinutes,
      'alertType': _alertType,
      'recurrenceType': _recurrenceType,
      'recurrenceDays': recurrenceDays,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 20;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Material(
            color: _bodyColor,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle('Alert'),
                          const SizedBox(height: 10),
                          _OptionGroup<int>(
                            options: _alertOptions,
                            selectedValue: _alertOffsetMinutes,
                            onSelected: (value) =>
                                setState(() => _alertOffsetMinutes = value),
                          ),
                          const SizedBox(height: 24),
                          const _SectionTitle('Alert Type'),
                          const SizedBox(height: 10),
                          Row(
                            children: List<Widget>.generate(
                                _alertTypeOptions.length, (index) {
                              final option = _alertTypeOptions[index];
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: index == _alertTypeOptions.length - 1
                                        ? 0
                                        : 8,
                                  ),
                                  child: _SelectionChip(
                                    label: option.label,
                                    selected: _alertType == option.value,
                                    onTap: () => setState(
                                        () => _alertType = option.value),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 24),
                          const _SectionTitle('Repeat'),
                          const SizedBox(height: 10),
                          _OptionGroup<String>(
                            options: _repeatOptions,
                            selectedValue: _recurrenceType,
                            onSelected: (value) =>
                                setState(() => _recurrenceType = value),
                          ),
                          if (_recurrenceType == 'weekly') ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List<Widget>.generate(
                                  _weekdayToggleLabels.length, (index) {
                                return _WeekdayChip(
                                  label: _weekdayToggleLabels[index],
                                  selected: _recurrenceDays.contains(index),
                                  onTap: () => _toggleRecurrenceDay(index),
                                );
                              }),
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              onPressed: _handleDone,
                              child: const Text('Done'),
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
      ),
    );
  }
}

class _SelectionOption<T> {
  final String label;
  final T value;

  const _SelectionOption({
    required this.label,
    required this.value,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _OptionGroup<T> extends StatelessWidget {
  final List<_SelectionOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const _OptionGroup({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AlertRepeatSheetState._cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: List<Widget>.generate(options.length, (index) {
          final option = options[index];
          return Column(
            children: [
              _OptionTile(
                label: option.label,
                selected: option.value == selectedValue,
                onTap: () => onSelected(option.value),
              ),
              if (index != options.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
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
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.88),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: _AlertRepeatSheetState._accentColor)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionChip({
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? _AlertRepeatSheetState._accentColor
                : _AlertRepeatSheetState._surfaceColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : _AlertRepeatSheetState._borderColor,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : _AlertRepeatSheetState._mutedTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WeekdayChip({
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
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: selected
                ? _AlertRepeatSheetState._accentColor
                : _AlertRepeatSheetState._surfaceColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : _AlertRepeatSheetState._borderColor,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : _AlertRepeatSheetState._mutedTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
