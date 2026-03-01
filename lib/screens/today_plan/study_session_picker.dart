// =============================================================
// StudySessionPicker — resource selector for study sessions
// Allows user to:
//   1. Continue FA essay reading (gap-aware, from tracker)
//   2. Pick specific FA pages
//   3. Pick UWorld system → topics
//   4. Pick Sketchy videos
//   5. Queue multiple study tasks in one session
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';

import 'study_flow_screen.dart';

/// A queued study task item
class StudyTask {
  final String type; // 'FA', 'UWORLD', 'SKETCHY_MICRO', 'SKETCHY_PHARM'
  final String label;
  final String detail;
  final List<int> pageNumbers; // for FA
  final List<int> topicIds; // for UWorld / Sketchy
  final int questionCount; // for UWorld

  const StudyTask({
    required this.type,
    required this.label,
    required this.detail,
    this.pageNumbers = const [],
    this.topicIds = const [],
    this.questionCount = 0,
  });
}

class StudySessionPicker extends StatefulWidget {
  final String dateKey;
  const StudySessionPicker({super.key, required this.dateKey});

  @override
  State<StudySessionPicker> createState() => _StudySessionPickerState();
}

class _StudySessionPickerState extends State<StudySessionPicker> {
  final List<StudyTask> _queue = [];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final nextPage = app.getNextContinuePage();
    final targetPages = app.getTodayTargetPages(
      count: settingsProvider.dailyFAGoal,
    );
    final totalRead = app.faPages.where((p) => p.status != 'unread').length;
    final totalPages = app.faPages.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ─────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Header ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.school_rounded, color: cs.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Start Study Session',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (_queue.isNotEmpty)
                      FilledButton.icon(
                        onPressed: _startSession,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text('Start (${_queue.length})',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Content ────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // ── FA Progress Banner ──────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            const Color(0xFF6366F1).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Text('📖', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FA Progress: $totalRead / $totalPages pages',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalPages > 0
                                        ? totalRead / totalPages
                                        : 0,
                                    backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                                    color: const Color(0xFF8B5CF6),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 1. Continue Essay Reading ─────────
                    _OptionCard(
                      icon: Icons.auto_stories_rounded,
                      color: const Color(0xFF8B5CF6),
                      title: 'Continue Essay Reading',
                      subtitle: 'Continue from page $nextPage · '
                          'Today\'s target: ${targetPages.length} pages',
                      onTap: () {
                        // Auto-set study plan start date
                        settingsProvider.ensureStudyPlanStartDate();
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => StudyFlowScreen(dateKey: widget.dateKey),
                        ));
                      },
                    ),

                    const SizedBox(height: 10),

                    // ── 2. Specific FA Pages ──────────────
                    _OptionCard(
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF10B981),
                      title: 'FA Pages',
                      subtitle: 'Select specific pages to study',
                      onTap: () => _showFAPagePicker(context, app),
                    ),

                    const SizedBox(height: 10),

                    // ── 3. UWorld Questions ────────────────
                    _OptionCard(
                      icon: Icons.quiz_rounded,
                      color: const Color(0xFFF59E0B),
                      title: 'UWorld Questions',
                      subtitle: '${app.uworldTopics.fold<int>(0, (s, t) => s + t.totalQuestions - t.doneQuestions)} questions remaining',
                      onTap: () => _showUWorldPicker(context, app),
                    ),

                    const SizedBox(height: 10),

                    // ── 4. Sketchy Micro ───────────────────
                    _OptionCard(
                      icon: Icons.play_circle_rounded,
                      color: const Color(0xFF3B82F6),
                      title: 'Sketchy Micro',
                      subtitle: '${app.sketchyMicroVideos.where((v) => !v.watched).length} unwatched videos',
                      onTap: () => _showSketchyPicker(context, app, 'micro'),
                    ),

                    const SizedBox(height: 10),

                    // ── 5. Sketchy Pharm ───────────────────
                    _OptionCard(
                      icon: Icons.play_circle_rounded,
                      color: const Color(0xFFEC4899),
                      title: 'Sketchy Pharm',
                      subtitle: '${app.sketchyPharmVideos.where((v) => !v.watched).length} unwatched videos',
                      onTap: () => _showSketchyPicker(context, app, 'pharm'),
                    ),

                    const SizedBox(height: 20),

                    // ── Queued Tasks ──────────────────────
                    if (_queue.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Queued Tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      ..._queue.asMap().entries.map((e) {
                        final i = e.key;
                        final task = e.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              _iconForType(task.type),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        )),
                                    Text(task.detail,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurface.withValues(alpha: 0.5),
                                        )),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close_rounded,
                                    size: 18, color: cs.error),
                                onPressed: () =>
                                    setState(() => _queue.removeAt(i)),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _iconForType(String type) {
    switch (type) {
      case 'FA':
        return const Icon(Icons.menu_book_rounded,
            color: Color(0xFF8B5CF6), size: 20);
      case 'UWORLD':
        return const Icon(Icons.quiz_rounded,
            color: Color(0xFFF59E0B), size: 20);
      case 'SKETCHY_MICRO':
        return const Icon(Icons.play_circle_rounded,
            color: Color(0xFF3B82F6), size: 20);
      case 'SKETCHY_PHARM':
        return const Icon(Icons.play_circle_rounded,
            color: Color(0xFFEC4899), size: 20);
      default:
        return const Icon(Icons.school_rounded, size: 20);
    }
  }

  void _startSession() {
    // For now, start the FA study flow (queue support can be extended)
    Navigator.pop(context);
    if (_queue.any((t) => t.type == 'FA')) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => StudyFlowScreen(dateKey: widget.dateKey),
      ));
    }
  }

  // ── FA Page Picker ──────────────────────────────────────────────
  void _showFAPagePicker(BuildContext context, AppProvider app) {
    final cs = Theme.of(context).colorScheme;
    final pages = List<FAPageOption>.generate(
      20,
      (i) {
        final nextPage = app.getNextContinuePage();
        final pageNum = nextPage + i;
        final faPage = app.faPages.where((p) => p.pageNum == pageNum).toList();
        final isRead = faPage.isNotEmpty && faPage.first.status != 'unread';
        return FAPageOption(pageNum: pageNum, isRead: isRead);
      },
    );

    int selectedCount = 4;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.6,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text('Select FA Pages', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
                      )),
                      const Spacer(),
                      Text('Count: ', style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5),
                      )),
                      DropdownButton<int>(
                        value: selectedCount,
                        items: [2, 4, 6, 8, 10]
                            .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                            .toList(),
                        onChanged: (v) => setSheetState(() => selectedCount = v!),
                        underline: const SizedBox(),
                        isDense: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pages.length,
                    itemBuilder: (ctx, i) {
                      final p = pages[i];
                      return ListTile(
                        leading: Icon(
                          p.isRead ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: p.isRead ? Colors.green : cs.onSurface.withValues(alpha: 0.3),
                        ),
                        title: Text('Page ${p.pageNum}',
                            style: TextStyle(
                              color: p.isRead
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface,
                            )),
                        dense: true,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final unread = pages.where((p) => !p.isRead).take(selectedCount).toList();
                        if (unread.isEmpty) {
                          Navigator.pop(ctx);
                          return;
                        }
                        setState(() {
                          _queue.add(StudyTask(
                            type: 'FA',
                            label: 'FA Pages',
                            detail: 'Pages ${unread.first.pageNum}–${unread.last.pageNum} ($selectedCount pages)',
                            pageNumbers: unread.map((p) => p.pageNum).toList(),
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Add $selectedCount pages to queue',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ── UWorld Picker ───────────────────────────────────────────────
  void _showUWorldPicker(BuildContext context, AppProvider app) {
    final cs = Theme.of(context).colorScheme;
    // Group topics by system
    final systems = <String, List<UWorldTopic>>{};
    for (final t in app.uworldTopics) {
      systems.putIfAbsent(t.system, () => []).add(t);
    }

    String? selectedSystem;
    int questionTarget = 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final topics = selectedSystem != null ? (systems[selectedSystem] ?? []) : <UWorldTopic>[];
          final remaining = topics.fold<int>(0, (s, t) => s + t.totalQuestions - t.doneQuestions);

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text('UWorld Questions', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
                  )),
                ),
                // System selector
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: systems.keys.map((sys) {
                      final isSelected = sys == selectedSystem;
                      final sysRemaining = systems[sys]!.fold<int>(
                          0, (s, t) => s + t.totalQuestions - t.doneQuestions);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$sys ($sysRemaining)',
                              style: TextStyle(fontSize: 12,
                                  color: isSelected ? Colors.white : cs.onSurface)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFF59E0B),
                          onSelected: (_) =>
                              setSheetState(() => selectedSystem = sys),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (selectedSystem != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text('$remaining questions remaining',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            )),
                        const Spacer(),
                        Text('Target: ', style: TextStyle(
                          fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5),
                        )),
                        DropdownButton<int>(
                          value: questionTarget,
                          items: [10, 20, 30, 40, 50]
                              .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => questionTarget = v!),
                          underline: const SizedBox(),
                          isDense: true,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: topics.length,
                      itemBuilder: (ctx, i) {
                        final t = topics[i];
                        final done = t.doneQuestions;
                        final total = t.totalQuestions;
                        return ListTile(
                          title: Text(t.subtopic, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('$done / $total done',
                              style: TextStyle(
                                fontSize: 12,
                                color: done == total ? Colors.green : cs.onSurface.withValues(alpha: 0.5),
                              )),
                          trailing: done < total
                              ? Icon(Icons.circle_outlined,
                                  size: 16, color: cs.onSurface.withValues(alpha: 0.3))
                              : const Icon(Icons.check_circle_rounded,
                                  size: 16, color: Colors.green),
                          dense: true,
                        );
                      },
                    ),
                  ),
                ] else
                  Expanded(
                    child: Center(
                      child: Text('Select a system above',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.35),
                          )),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedSystem == null
                          ? null
                          : () {
                              setState(() {
                                _queue.add(StudyTask(
                                  type: 'UWORLD',
                                  label: 'UWorld — $selectedSystem',
                                  detail: '$questionTarget questions',
                                  questionCount: questionTarget,
                                ));
                              });
                              Navigator.pop(ctx);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Add $questionTarget UWorld Qs to queue',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ── Sketchy Picker ──────────────────────────────────────────────
  void _showSketchyPicker(BuildContext context, AppProvider app, String type) {
    final cs = Theme.of(context).colorScheme;
    final videos = type == 'micro' ? app.sketchyMicroVideos : app.sketchyPharmVideos;
    final label = type == 'micro' ? 'Sketchy Micro' : 'Sketchy Pharm';
    final color = type == 'micro' ? const Color(0xFF3B82F6) : const Color(0xFFEC4899);

    // Group by category
    final categories = <String, List<SketchyVideo>>{};
    for (final v in videos) {
      categories.putIfAbsent(v.category, () => []).add(v);
    }

    String? selectedCategory;
    final selectedVideos = <int>{}; // ids

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final catVideos = selectedCategory != null
              ? (categories[selectedCategory] ?? [])
              : <SketchyVideo>[];
          catVideos.where((v) => !v.watched).toList(); // availability check

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(label, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
                  )),
                ),
                // Category chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: categories.keys.map((cat) {
                      final isSelected = cat == selectedCategory;
                      final unwatchedCount = categories[cat]!
                          .where((v) => !v.watched)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$cat ($unwatchedCount)',
                              style: TextStyle(fontSize: 12,
                                  color: isSelected ? Colors.white : cs.onSurface)),
                          selected: isSelected,
                          selectedColor: color,
                          onSelected: (_) =>
                              setSheetState(() => selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (selectedCategory != null)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: catVideos.length,
                      itemBuilder: (ctx, i) {
                        final v = catVideos[i];
                        final isSelected = selectedVideos.contains(v.id);
                        return CheckboxListTile(
                          value: v.watched ? true : isSelected,
                          onChanged: v.watched
                              ? null
                              : (val) {
                                  setSheetState(() {
                                    if (val == true) {
                                      selectedVideos.add(v.id!);
                                    } else {
                                      selectedVideos.remove(v.id);
                                    }
                                  });
                                },
                          title: Text(
                            v.title,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: v.watched ? TextDecoration.lineThrough : null,
                              color: v.watched
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface,
                            ),
                          ),
                          subtitle: Text(v.subcategory,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              )),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text('Select a category above',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.35),
                          )),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedVideos.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _queue.add(StudyTask(
                                  type: type == 'micro'
                                      ? 'SKETCHY_MICRO'
                                      : 'SKETCHY_PHARM',
                                  label: '$label — $selectedCategory',
                                  detail: '${selectedVideos.length} videos',
                                  topicIds: selectedVideos.toList(),
                                ));
                              });
                              Navigator.pop(ctx);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          selectedVideos.isEmpty
                              ? 'Select videos'
                              : 'Add ${selectedVideos.length} videos to queue',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

// ── Option Card ──────────────────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    )),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper ───────────────────────────────────────────────────────
class FAPageOption {
  final int pageNum;
  final bool isRead;
  const FAPageOption({required this.pageNum, required this.isRead});
}
