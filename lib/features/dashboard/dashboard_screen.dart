import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../todays_plan/todays_plan_provider.dart';
import '../fa_logger/fa_logger_provider.dart';
import '../knowledge_base/kb_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks    = ref.watch(todayTasksProvider);
    final sessions = ref.watch(faSessionsProvider);
    final entries  = ref.watch(kbProvider);
    final done     = tasks.where((t) => t.isDone).length;
    final total    = tasks.length;
    final progress = total == 0 ? 0.0 : done / total;
    final notifier = ref.read(faSessionsProvider.notifier);

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
                  // Greeting
                  Text(_greeting(), style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Dashboard', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 24),

                  // Today progress card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.today_rounded, color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Text("Today's Plan", style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go('/today'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                            child: const Text('View', style: TextStyle(fontSize: 12)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: AppColors.accentGlow,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('$done of $total tasks done',
                              style: Theme.of(context).textTheme.bodyMedium),
                          Text('${(progress * 100).round()}%',
                              style: const TextStyle(
                                  color: AppColors.accent, fontWeight: FontWeight.w700)),
                        ]),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

                  const SizedBox(height: 16),

                  // Stats row
                  Row(children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        onTap: () => context.go('/fa-logger'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.science_rounded, color: AppColors.accent, size: 18),
                              const SizedBox(width: 6),
                              Text('FA Logger', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                            ]),
                            const SizedBox(height: 10),
                            Text('${notifier.totalPages()}',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28)),
                            Text('total pages',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('${sessions.length} sessions',
                                style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        onTap: () => context.go('/knowledge'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.menu_book_rounded, color: AppColors.accentLight, size: 18),
                              const SizedBox(width: 6),
                              Text('Knowledge', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                            ]),
                            const SizedBox(height: 10),
                            Text('${entries.length}',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28)),
                            Text('entries saved',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('Tap to browse',
                                style: const TextStyle(fontSize: 11, color: AppColors.accentLight, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ]).animate(delay: 100.ms).fadeIn().slideY(begin: 0.08),

                  const SizedBox(height: 24),

                  // Quick nav grid
                  Text('Quick Access', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: _quickLinks.asMap().entries.map((e) =>
                      _QuickLink(item: e.value)
                          .animate(delay: (e.key * 40).ms)
                          .fadeIn()
                          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                    ).toList(),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return '🌅 Good morning';
    if (h < 17) return '☀️ Good afternoon';
    if (h < 21) return '🌇 Good evening';
    return '🌙 Late night grind';
  }

  static const _quickLinks = [
    _Link(icon: Icons.timer_rounded,            label: 'Timer',    route: '/timer'),
    _Link(icon: Icons.medical_services_rounded, label: 'FMGE',     route: '/fmge'),
    _Link(icon: Icons.repeat_rounded,           label: 'Revision', route: '/revision'),
    _Link(icon: Icons.schedule_rounded,         label: 'Time Log', route: '/time-logger'),
    _Link(icon: Icons.calendar_month_rounded,   label: 'Calendar', route: '/calendar'),
    _Link(icon: Icons.bar_chart_rounded,        label: 'Tracker',  route: '/tracker'),
    _Link(icon: Icons.smart_toy_rounded,        label: 'AI Chat',  route: '/ai-chat'),
    _Link(icon: Icons.insights_rounded,         label: 'Analytics',route: '/analytics'),
  ];
}

class _Link {
  final IconData icon;
  final String label, route;
  const _Link({required this.icon, required this.label, required this.route});
}

class _QuickLink extends StatelessWidget {
  final _Link item;
  const _QuickLink({required this.item});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.route),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(children: [
          Icon(item.icon, color: AppColors.accent, size: 24),
          const SizedBox(height: 6),
          Text(item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
