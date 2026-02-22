import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}

const _dockItems = [
  _NavItem(icon: Icons.today_rounded,       label: 'Today',     route: '/today'),
  _NavItem(icon: Icons.menu_book_rounded,   label: 'Knowledge', route: '/knowledge'),
  _NavItem(icon: Icons.science_rounded,     label: 'FA Logger', route: '/fa-logger'),
  _NavItem(icon: Icons.timer_rounded,       label: 'Timer',     route: '/timer'),
  _NavItem(icon: Icons.grid_view_rounded,   label: 'More',      route: ''),
];

const _allScreens = [
  _NavItem(icon: Icons.dashboard_rounded,         label: 'Dashboard',     route: '/dashboard'),
  _NavItem(icon: Icons.today_rounded,             label: "Today's Plan",  route: '/today'),
  _NavItem(icon: Icons.menu_book_rounded,         label: 'Knowledge',     route: '/knowledge'),
  _NavItem(icon: Icons.science_rounded,           label: 'FA Logger',     route: '/fa-logger'),
  _NavItem(icon: Icons.timer_rounded,             label: 'Focus Timer',   route: '/timer'),
  _NavItem(icon: Icons.medical_services_rounded,  label: 'FMGE',          route: '/fmge'),
  _NavItem(icon: Icons.schedule_rounded,          label: 'Time Logger',   route: '/time-logger'),
  _NavItem(icon: Icons.repeat_rounded,            label: 'Revision',      route: '/revision'),
  _NavItem(icon: Icons.calendar_month_rounded,    label: 'Calendar',      route: '/calendar'),
  _NavItem(icon: Icons.bar_chart_rounded,         label: 'Study Tracker', route: '/tracker'),
  _NavItem(icon: Icons.smart_toy_rounded,         label: 'AI Chat',       route: '/ai-chat'),
  _NavItem(icon: Icons.insights_rounded,          label: 'Analytics',     route: '/analytics'),
  _NavItem(icon: Icons.settings_rounded,          label: 'Settings',      route: '/settings'),
];

class NavigationShell extends StatefulWidget {
  final Widget child;
  const NavigationShell({super.key, required this.child});
  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 380.ms);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack, reverseCurve: Curves.easeInQuart);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _show() {
    HapticFeedback.lightImpact();
    setState(() => _visible = true);
    _ctrl.forward();
  }

  void _hide() {
    _ctrl.reverse().then((_) { if (mounted) setState(() => _visible = false); });
  }

  void _go(String route) {
    _hide();
    if (route.isNotEmpty) context.go(route);
  }

  void _showMore() {
    _hide();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoreSheet(
        onNavigate: (r) { Navigator.pop(context); context.go(r); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _visible ? _hide : null,
        child: Stack(
          children: [
            widget.child,
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_visible)
                    AnimatedBuilder(
                      animation: _anim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, 20 * (1 - _anim.value)),
                        child: Opacity(opacity: _anim.value.clamp(0.0, 1.0), child: child),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassCard(
                          blurSigma: 30, borderRadius: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _dockItems.map((item) => _DockBtn(
                              item: item,
                              onTap: () => item.route.isEmpty ? _showMore() : _go(item.route),
                            )).toList(),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onVerticalDragEnd: (d) {
                      if (d.velocity.pixelsPerSecond.dy < -300) _show();
                      else if (d.velocity.pixelsPerSecond.dy > 300) _hide();
                    },
                    onTap: _visible ? _hide : _show,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 16, top: 8),
                      color: Colors.transparent,
                      child: Center(
                        child: AnimatedContainer(
                          duration: 200.ms,
                          width: _visible ? 40 : 60,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white38 : Colors.black26,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockBtn extends StatelessWidget {
  final _NavItem item;
  final VoidCallback onTap;
  const _DockBtn({required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(height: 4),
          Text(item.label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    ).animate().scale(begin: const Offset(0.8, 0.8), duration: 200.ms, curve: Curves.easeOutBack);
  }
}

class _MoreSheet extends StatelessWidget {
  final void Function(String) onNavigate;
  const _MoreSheet({required this.onNavigate});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x12FFFFFF) : const Color(0xCCFFFFFF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(
              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x4DFFFFFF),
              width: 0.5,
            )),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('All Screens', style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, childAspectRatio: 0.82,
                  crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
                itemCount: _allScreens.length,
                itemBuilder: (_, i) {
                  final item = _allScreens[i];
                  return GestureDetector(
                    onTap: () => onNavigate(item.route),
                    child: Column(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accentGlow,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0x4D6366F1), width: 0.5),
                          ),
                          child: Icon(item.icon, color: AppColors.accent, size: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.label, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ).animate(delay: (i * 25).ms).fadeIn().scale(
                    begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
