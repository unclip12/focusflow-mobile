// =============================================================
// DailyTrackerScreen â€” full day view with sections:
//   Mood check-in, Water intake, Study hours (read-only),
//   Habits checklist, Daily notes.
// FAB â†’ AddHabitSheet.
// Android rules: resizeToAvoidBottomInset: true (via AppScaffold),
//                enableDrag: false, useSafeArea: true on sheets.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';

import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/daily_tracker/habit_card.dart';
import 'package:focusflow_mobile/screens/daily_tracker/add_habit_sheet.dart';

// â”€â”€ Mood emojis â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const _moods = ['ðŸ˜¢', 'ðŸ˜•', 'ðŸ˜', 'ðŸ˜Š', 'ðŸ¤©'];


class DailyTrackerScreen extends StatefulWidget {
  const DailyTrackerScreen({super.key});

  @override
  State<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends State<DailyTrackerScreen> {
  DateTime _currentDate = DateTime.now();
  int _selectedMood = -1; // -1 = none
  int _waterGlasses = 0;
  final _notesCtrl = TextEditingController();

  // Local habits list (would be persisted via AppProvider in production)
  final List<_HabitItem> _habits = [];

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_currentDate);

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ Date navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _changeDate(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentDate = _currentDate.add(Duration(days: delta));
      _selectedMood = -1;
      _waterGlasses = 0;
      _notesCtrl.clear();
    });
  }

  // â”€â”€ Study hours from time logs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  double _studyHours(AppProvider ap) {
    final mins = ap.timeLogs
        .where((t) => t.date == _dateKey)
        .fold<int>(0, (sum, t) => sum + t.durationMinutes);
    return mins / 60.0;
  }

  // â”€â”€ Show add habit sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showAddHabitSheet() {
    showModalBottomSheet<void>(
      context: context,
      enableDrag: false,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHabitSheet(
        onSave: (name, frequency, color) {
          setState(() {
            _habits.add(_HabitItem(
              id: const Uuid().v4(),
              name: name,
              frequency: frequency,
              color: color,
            ));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == _dateKey;

    return AppScaffold(
      screenName: 'Daily Tracker',
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAddHabitSheet,
        backgroundColor: cs.primary,
        child: Icon(Icons.add_rounded, color: cs.onPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // DATE HEADER
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _DateHeader(
            date: _currentDate,
            isToday: isToday,
            onPrev: () => _changeDate(-1),
            onNext: () => _changeDate(1),
          ),
          const SizedBox(height: 16),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // MOOD CHECK-IN
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _sectionLabel('How are you feeling?', theme, cs),
          const SizedBox(height: 8),
          _MoodSelector(
            selected: _selectedMood,
            onSelect: (i) {
              HapticFeedback.selectionClick();
              setState(() => _selectedMood = i);
            },
          ),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // WATER INTAKE
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _sectionLabel('Water Intake', theme, cs),
          const SizedBox(height: 8),
          _WaterTracker(
            glasses: _waterGlasses,
            onIncrement: () {
              if (_waterGlasses < 8) {
                HapticFeedback.selectionClick();
                setState(() => _waterGlasses++);
              }
            },
            onDecrement: () {
              if (_waterGlasses > 0) {
                HapticFeedback.selectionClick();
                setState(() => _waterGlasses--);
              }
            },
          ),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // STUDY HOURS (read-only)
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _sectionLabel('Study Hours Today', theme, cs),
          const SizedBox(height: 8),
          _StudyHoursCard(hours: _studyHours(ap)),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // HABITS CHECKLIST
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          Row(
            children: [
              Expanded(child: _sectionLabel('Habits', theme, cs)),
              if (_habits.isNotEmpty)
                Text(
                  '${_habits.where((h) => h.completed).length}/${_habits.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_habits.isEmpty)
            _EmptyHabits(onAdd: _showAddHabitSheet)
          else
            ..._habits.map((h) {
              return HabitCard(
                name: h.name,
                completed: h.completed,
                color: h.color,
                frequency: h.frequency,
                streakDays: h.streak,
                onToggle: (val) {
                  HapticFeedback.lightImpact();
                  setState(() => h.completed = val);
                },
              );
            }),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // DAILY NOTES
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _sectionLabel('Daily Notes', theme, cs),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 4,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'How was your day? What did you learn?',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 60), // space for FAB
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// LOCAL HABIT MODEL
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _HabitItem {
  final String id;
  final String name;
  final String frequency;
  final Color color;
  bool completed = false;
  int streak = 0;

  _HabitItem({
    required this.id,
    required this.name,
    required this.frequency,
    required this.color,
  });
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HELPER WIDGETS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

Widget _sectionLabel(String label, ThemeData theme, ColorScheme cs) {
  return Text(
    label,
    style: theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface.withValues(alpha: 0.5),
    ),
  );
}

// â”€â”€ Date header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DateHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DateHeader({
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = DateFormat('EEEE, d MMMM').format(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPrev,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isToday)
                  Text(
                    'Today',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Mood selector â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MoodSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _MoodSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_moods.length, (i) {
          final isSelected = selected == i;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(
                _moods[i],
                style: TextStyle(fontSize: isSelected ? 30 : 24),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// â”€â”€ Water tracker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _WaterTracker extends StatelessWidget {
  final int glasses;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _WaterTracker({
    required this.glasses,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Glass icon + count
          const Text('ðŸ’§', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(
            '$glasses',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.blue.shade400,
            ),
          ),
          Text(
            ' / 8 glasses',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const Spacer(),

          // -/+ buttons
          _circleBtn(Icons.remove_rounded, glasses > 0, onDecrement, cs),
          const SizedBox(width: 8),
          _circleBtn(Icons.add_rounded, glasses < 8, onIncrement, cs),
        ],
      ),
    );
  }

  Widget _circleBtn(
      IconData icon, bool enabled, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? cs.primary.withValues(alpha: 0.1)
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? cs.primary
              : cs.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

// â”€â”€ Study hours card (read-only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StudyHoursCard extends StatelessWidget {
  final double hours;
  const _StudyHoursCard({required this.hours});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.menu_book_rounded,
                size: 20, color: Colors.green.shade400),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hours.toStringAsFixed(1)} hrs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'from time logs',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Progress ring
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: (hours / 8.0).clamp(0.0, 1.0),
                  strokeWidth: 4,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
                ),
                Center(
                  child: Text(
                    '${(hours / 8.0 * 100).clamp(0, 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: Colors.green.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Empty habits state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EmptyHabits extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHabits({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(Icons.checklist_rounded,
                size: 36,
                color: cs.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(
              'No habits yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add your first habit',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
