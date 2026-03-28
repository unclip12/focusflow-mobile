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

class _TimePickerSheetState extends State<TimePickerSheet> {
  static const List<int> _durations = <int>[1, 15, 30, 45, 60, 90, 120, 180];
  static const Color _kBodyColor = Color(0xFF171717);
  static const Color _kCardColor = Color(0xFF262629);
  static const Color _kAccentColor = Color(0xFFFF8E88);
  static const Color _kMutedTextColor = Color(0xFFAAAAB1);

  late final FixedExtentScrollController _wheelController;
  late int _selectedIndex;
  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _slotIndexForTime(widget.initialStartTime);
    _selectedDuration = _durations.contains(widget.initialDurationMinutes)
        ? widget.initialDurationMinutes
        : 90;
    _wheelController = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  List<int> get _slots =>
      List<int>.generate(96, (index) => index * 15, growable: false);

  int _slotIndexForTime(String hhmm) {
    final minutes = _minutesFromHhmm(hhmm);
    final snapped = (minutes / 15).round().clamp(0, 95);
    return snapped;
  }

  int _minutesFromHhmm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      return 0;
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60 + minute).clamp(0, 1439);
  }

  String _hhmmFromMinutes(int minutes) {
    final safeMinutes = minutes.clamp(0, 1439);
    final hour = safeMinutes ~/ 60;
    final minute = safeMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeOfDay(int minutes) {
    final hour24 = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    final suffix = hour24 < 12 ? 'AM' : 'PM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _formatRangeLabel(int startMinutes, int durationMinutes) {
    final endMinutes = (startMinutes + durationMinutes) % (24 * 60);
    final startSuffix = (startMinutes ~/ 60) < 12 ? 'AM' : 'PM';
    final endSuffix = (endMinutes ~/ 60) < 12 ? 'AM' : 'PM';
    final startLabel = _formatTimeOfDay(startMinutes);
    final endLabel = _formatTimeOfDay(endMinutes);
    if (startSuffix == endSuffix) {
      return '${startLabel.replaceAll(' $startSuffix', '')} – $endLabel';
    }
    return '$startLabel – $endLabel';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours > 0 && remainder > 0) {
      return '$hours hr, $remainder min';
    }
    if (hours > 0) {
      return hours == 1 ? '1 hr' : '$hours hr';
    }
    return '$minutes min';
  }

  String _durationChipLabel(int minutes) {
    switch (minutes) {
      case 1:
        return '1 min';
      case 15:
        return '15 min';
      case 30:
        return '30 min';
      case 45:
        return '45 min';
      case 60:
        return '1h';
      case 90:
        return '1.5h';
      case 120:
        return '2h';
      case 180:
        return '3h';
      default:
        return '$minutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final startMinutes = _slots[_selectedIndex];
    final rangeLabel = _formatRangeLabel(startMinutes, _selectedDuration);
    final durationLabel = _formatDuration(_selectedDuration);
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
                        '$rangeLabel ($_durationChipLabelInline(_selectedDuration))',
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
                        const _SectionHeader(label: 'Time'),
                        const SizedBox(height: 14),
                        Container(
                          height: 246,
                          decoration: BoxDecoration(
                            color: _kCardColor,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                left: 18,
                                right: 18,
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: _kAccentColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              ListWheelScrollView.useDelegate(
                                controller: _wheelController,
                                itemExtent: 44,
                                physics: const FixedExtentScrollPhysics(),
                                diameterRatio: 2.0,
                                perspective: 0.002,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: _slots.length,
                                  builder: (context, index) {
                                    final isSelected = index == _selectedIndex;
                                    return Center(
                                      child: Text(
                                        _formatRangeLabel(
                                          _slots[index],
                                          _selectedDuration,
                                        ),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.38),
                                          fontSize: isSelected ? 21 : 18,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        const _SectionHeader(label: 'Duration'),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: _kCardColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _durations.map((duration) {
                                final isSelected = duration == _selectedDuration;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(_durationChipLabel(duration)),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedDuration = duration;
                                      });
                                    },
                                    showCheckmark: false,
                                    backgroundColor: Colors.transparent,
                                    selectedColor: _kAccentColor,
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.transparent
                                          : Colors.transparent,
                                    ),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : _kMutedTextColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                );
                              }).toList(growable: false),
                            ),
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
                                'startTime': _hhmmFromMinutes(startMinutes),
                                'durationMinutes': _selectedDuration,
                              });
                            },
                            child: Text('Continue  •  $durationLabel'),
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

  String _durationChipLabelInline(int minutes) {
    if (minutes == 90) {
      return '1 hr, 30 min';
    }
    return _formatDuration(minutes);
  }
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

  const _SectionHeader({required this.label});

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
        Container(
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
      ],
    );
  }
}
