import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import 'todays_plan_provider.dart';

class TodaysPlanScreen extends ConsumerWidget {
  const TodaysPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(todayTasksProvider);
    final done = tasks.where((t) => t.isDone).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : done / total;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDate(now), style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text("Today's Plan", style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72, height: 72,
                          child: CustomPaint(
                            painter: _RingPainter(progress),
                            child: Center(
                              child: Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$done of $total done', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                total == 0 ? 'Add your first task!'
                                    : done == total ? '🎉 All done! Great work!'
                                    : '${total - done} remaining',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
                      if (tasks.isNotEmpty)
                        Text('${tasks.length} total', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (tasks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.checklist_rounded, size: 56, color: AppColors.accent),
                      const SizedBox(height: 12),
                      Text('No tasks yet', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Tap + to add your first task', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ).animate().fadeIn(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Dismissible(
                    key: Key(tasks[i].id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => ref.read(todayTasksProvider.notifier).delete(tasks[i].id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_rounded, color: AppColors.error),
                    ),
                    child: _TaskCard(task: tasks[i]),
                  ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.08),
                ),
                childCount: tasks.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddTaskSheet(
        onAdd: (title, cat, pri) => ref.read(todayTasksProvider.notifier).add(title, cat, pri),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

class _TaskCard extends ConsumerWidget {
  final Task task;
  const _TaskCard({required this.task});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priColors = [AppColors.info, AppColors.warning, AppColors.error];
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(todayTasksProvider.notifier).toggle(task.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: task.isDone ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: task.isDone ? AppColors.accent : (isDark ? Colors.white38 : Colors.black26),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: task.isDone ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    color: task.isDone ? (isDark ? Colors.white38 : Colors.black38) : null,
                  ),
                ),
                const SizedBox(height: 3),
                Row(children: [
                  Text(task.category, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  const SizedBox(width: 8),
                  Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: priColors[task.priority], shape: BoxShape.circle)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final void Function(String, String, int) onAdd;
  const _AddTaskSheet({required this.onAdd});
  @override State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _ctrl = TextEditingController();
  String _category = 'General';
  int _priority = 1;
  static const _cats = ['General', 'FMGE', 'FA', 'Clinical', 'Theory', 'Revision'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 20),
            Text('Add Task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: _ctrl, autofocus: true,
                decoration: const InputDecoration(hintText: 'Task title...')),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _cats.map((c) => FilterChip(
              label: Text(c), selected: _category == c,
              onSelected: (_) => setState(() => _category = c),
              selectedColor: AppColors.accentGlow,
            )).toList()),
            const SizedBox(height: 16),
            Text('Priority', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(children: [
              for (int p = 0; p < 3; p++)
                Padding(padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(['Low', 'Medium', 'High'][p]),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                    selectedColor: [AppColors.info, AppColors.warning, AppColors.error][p].withValues(alpha: 0.25),
                  )),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (_ctrl.text.trim().isNotEmpty) {
                    widget.onAdd(_ctrl.text.trim(), _category, _priority);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    canvas.drawCircle(c, r,
        Paint()..color = AppColors.accentGlow..strokeWidth = 6..style = PaintingStyle.stroke);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -pi / 2, 2 * pi * progress, false,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }
  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
