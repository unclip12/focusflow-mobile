// =============================================================
// CalendarDateMarker — dots below date number in calendar cell.
// Shows up to 3 colored dots representing activity types:
//   blue   = DayPlan Block
//   green  = StudyPlanItem (study session)
//   amber  = StudyPlanItem deadline (not completed)
// =============================================================

import 'package:flutter/material.dart';

enum CalendarActivityType { block, study, deadline }

class CalendarDateMarker extends StatelessWidget {
  final List<CalendarActivityType> types;

  const CalendarDateMarker({super.key, required this.types});

  static Color _colorFor(CalendarActivityType type, ColorScheme cs) {
    switch (type) {
      case CalendarActivityType.block:
        return Colors.blue.shade400;
      case CalendarActivityType.study:
        return Colors.green.shade400;
      case CalendarActivityType.deadline:
        return Colors.amber.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Deduplicate and cap at 3 dots
    final unique = types.toSet().toList();
    final dots = unique.take(3).toList();

    if (dots.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: dots.map((type) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: _colorFor(type, cs),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
