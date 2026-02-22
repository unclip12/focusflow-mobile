import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import 'fa_logger_provider.dart';

class FALoggerScreen extends ConsumerWidget {
  const FALoggerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions       = ref.watch(faSessionsProvider);
    final notifier       = ref.read(faSessionsProvider.notifier);
    final pagesBySubject = notifier.pagesBySubject;
    final totalPages     = notifier.totalPages();
    final totalMin       = notifier.totalMinutes();

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
                  Text('FA Logger', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 2),
                  Text('First Aid Study Tracker', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _StatCard(label: 'Pages', value: '$totalPages', icon: Icons.menu_book_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Hours', value: (totalMin / 60).toStringAsFixed(1), icon: Icons.schedule_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Sessions', value: '${sessions.length}', icon: Icons.bar_chart_rounded)),
                  ]).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),
                  Text('Subjects', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1.7,
                crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final subject = faSubjects[i];
                  final pages   = pagesBySubject[subject] ?? 0;
                  final color   = AppColors.subjectColors[i % AppColors.subjectColors.length];
                  return _SubjectCard(
                    subject: subject, pages: pages, color: color,
                    onTap: () => _showLogSheet(context, ref, subject, color),
                  ).animate(delay: (i * 25).ms).fadeIn().scale(
                    begin: const Offset(0.93, 0.93), curve: Curves.easeOut);
                },
                childCount: faSubjects.length,
              ),
            ),
          ),
          if (sessions.isNotEmpty) ...[            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text('Recent Sessions', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final s     = sessions[i];
                  final color = AppColors.subjectColors[
                    faSubjects.indexOf(s.subject) % AppColors.subjectColors.length
                  ];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Dismissible(
                      key: Key(s.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => ref.read(faSessionsProvider.notifier).delete(s.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_rounded, color: AppColors.error),
                      ),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Container(width: 4, height: 44,
                            decoration: BoxDecoration(
                              color: color, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.subject,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                              Text('${s.pages} pages  •  ${s.durationMin} min',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              if (s.notes != null)
                                Text(s.notes!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          )),
                          Text(_fmt(s.date),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                        ]),
                      ),
                    ).animate(delay: (i * 30).ms).fadeIn().slideX(begin: 0.08),
                  );
                },
                childCount: sessions.length > 15 ? 15 : sessions.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  void _showLogSheet(BuildContext context, WidgetRef ref, String subject, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LogSheet(
        subject: subject, color: color,
        onLog: (p, d, n) => ref.read(faSessionsProvider.notifier).addSession(subject, p, d, n),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}';
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    child: Column(children: [
      Icon(icon, color: AppColors.accent, size: 22),
      const SizedBox(height: 6),
      Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
      Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10)),
    ]),
  );
}

class _SubjectCard extends StatelessWidget {
  final String subject;
  final int pages;
  final Color color;
  final VoidCallback onTap;
  const _SubjectCard({required this.subject, required this.pages, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(subject,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$pages pg', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
          Icon(Icons.add_circle_rounded, color: color.withOpacity(0.7), size: 20),
        ]),
      ],
    ),
  );
}

class _LogSheet extends StatefulWidget {
  final String subject;
  final Color color;
  final void Function(int, int, String?) onLog;
  const _LogSheet({required this.subject, required this.color, required this.onLog});
  @override State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  int _pages = 10;
  int _duration = 30;
  final _notesCtrl = TextEditingController();

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
            Row(children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text('Log: ${widget.subject}',
                  style: Theme.of(context).textTheme.titleLarge)),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Pages Read', style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
                child: Text('$_pages', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: widget.color)),
              ),
            ]),
            Slider(
              value: _pages.toDouble(), min: 1, max: 150, divisions: 149,
              activeColor: widget.color,
              onChanged: (v) => setState(() => _pages = v.round()),
            ),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Duration', style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
                child: Text('${_duration}m', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: widget.color)),
              ),
            ]),
            Slider(
              value: _duration.toDouble(), min: 5, max: 300, divisions: 59,
              activeColor: widget.color,
              onChanged: (v) => setState(() => _duration = (v / 5).round() * 5),
            ),
            const SizedBox(height: 12),
            TextField(controller: _notesCtrl,
                decoration: const InputDecoration(hintText: 'Notes (optional)...')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  widget.onLog(_pages, _duration,
                      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('Log Session', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
