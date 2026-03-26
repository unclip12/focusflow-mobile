import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/library/add_note_sheet.dart';
import 'package:focusflow_mobile/screens/library/edit_metadata_sheet.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';

// ══════════════════════════════════════════════════════════════════
// UWorld Detail Sheet — premium liquid-glass redesign
// ══════════════════════════════════════════════════════════════════

class UWorldDetailSheet extends StatefulWidget {
  final AppProvider app;
  final UWorldTopic topic;

  const UWorldDetailSheet({
    super.key,
    required this.app,
    required this.topic,
  });

  @override
  State<UWorldDetailSheet> createState() => _UWorldDetailSheetState();
}

class _UWorldDetailSheetState extends State<UWorldDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  UWorldTopic get _topic {
    return widget.app.uworldTopics.firstWhere(
      (t) => t.id == widget.topic.id,
      orElse: () => widget.topic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topic = _topic;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Drag handle ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // ── Header ──────────────────────────────────────
            _UWorldHeader(
              topic: topic,
              isDark: isDark,
              onEdit: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => EditMetadataSheet(
                    initialTitle: topic.customTitle,
                    initialDescription: topic.userDescription,
                    onSave: (title, desc) {
                      final updated = topic.copyWith(
                        customTitle: title,
                        userDescription: desc,
                      );
                      widget.app.updateUWorldMetadata(updated);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // ── Tab Bar ─────────────────────────────────────
            _GlassTabBar(
              controller: _tabController,
              tabs: const ['Progress', 'Notes & Attachments'],
              isDark: isDark,
            ),
            const SizedBox(height: 4),
            // ── Tab Content ─────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProgressTab(
                    topic: topic,
                    app: widget.app,
                    scrollController: scrollController,
                    isDark: isDark,
                  ),
                  _NotesTab(
                    itemId: 'uworld:${topic.id}',
                    itemType: 'uworld',
                    app: widget.app,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════════

class _UWorldHeader extends StatelessWidget {
  final UWorldTopic topic;
  final bool isDark;
  final VoidCallback onEdit;

  const _UWorldHeader({
    required this.topic,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final doneProgress = topic.totalQuestions > 0
        ? topic.doneQuestions / topic.totalQuestions
        : 0.0;
    final isDone = topic.doneQuestions >= topic.totalQuestions &&
        topic.totalQuestions > 0;

    final statusColor =
        isDone ? DashboardColors.success : DashboardColors.warning;
    final statusLabel =
        isDone ? 'COMPLETED' : '${(doneProgress * 100).round()}% DONE';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient accent strip
          Container(
            width: 4,
            height: 48,
            margin: const EdgeInsets.only(top: 4, right: 14),
            decoration: BoxDecoration(
              gradient: DashboardColors.verticalAccentGradient(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title + breadcrumbs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.customTitle ?? topic.subtopic,
                        style: _inter(
                          size: 20,
                          weight: FontWeight.w700,
                          color: DashboardColors.textPrimary(isDark),
                        ),
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: _inter(
                          size: 9,
                          weight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                if (topic.customTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Original: ${topic.subtopic}',
                    style: _inter(
                      size: 11,
                      weight: FontWeight.w400,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Breadcrumb chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _BreadcrumbChip(
                      label: 'UWorld',
                      isDark: isDark,
                      color: DashboardColors.primary,
                    ),
                    _BreadcrumbChip(
                      label: topic.system,
                      isDark: isDark,
                    ),
                  ],
                ),
                if (topic.userDescription?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    topic.userDescription!,
                    style: _inter(
                      size: 12,
                      weight: FontWeight.w400,
                      color: DashboardColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Edit button
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : DashboardColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DashboardColors.glassBorder(isDark),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.edit_rounded,
                size: 16,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// PROGRESS TAB — accuracy ring + stepper + quick buttons
// ══════════════════════════════════════════════════════════════════

class _ProgressTab extends StatefulWidget {
  final UWorldTopic topic;
  final AppProvider app;
  final ScrollController scrollController;
  final bool isDark;

  const _ProgressTab({
    required this.topic,
    required this.app,
    required this.scrollController,
    required this.isDark,
  });

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  late int _done;
  late int _correct;

  @override
  void initState() {
    super.initState();
    _done = widget.topic.doneQuestions;
    _correct = widget.topic.correctQuestions;
  }

  @override
  void didUpdateWidget(covariant _ProgressTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic.doneQuestions != widget.topic.doneQuestions ||
        oldWidget.topic.correctQuestions != widget.topic.correctQuestions) {
      _done = widget.topic.doneQuestions;
      _correct = widget.topic.correctQuestions;
    }
  }

  void _updateDone(int delta) {
    setState(() {
      _done = (_done + delta).clamp(0, widget.topic.totalQuestions);
      _correct = _correct.clamp(0, _done);
    });
  }

  void _updateCorrect(int delta) {
    setState(() {
      _correct = (_correct + delta).clamp(0, _done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final topic = widget.topic;
    final accuracy = _done > 0 ? _correct / _done : 0.0;
    final doneProgress =
        topic.totalQuestions > 0 ? _done / topic.totalQuestions : 0.0;

    // Accuracy color
    Color accColor;
    if (accuracy >= 0.8) {
      accColor = DashboardColors.success;
    } else if (accuracy >= 0.5) {
      accColor = DashboardColors.warning;
    } else if (_done > 0) {
      accColor = DashboardColors.danger;
    } else {
      accColor = DashboardColors.textSecondary;
    }

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      children: [
        // ── Accuracy Ring ──────────────────────────────────
        _GlassContainer(
          isDark: isDark,
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: accuracy),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: _RingPainter(
                        progress: value,
                        color: accColor,
                        trackColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : accColor.withValues(alpha: 0.08),
                        strokeWidth: 6,
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _done > 0
                              ? '${(accuracy * 100).round()}%'
                              : '—',
                          style: _inter(
                            size: 20,
                            weight: FontWeight.w800,
                            color: DashboardColors.textPrimary(isDark),
                          ),
                        ),
                        Text(
                          'accuracy',
                          style: _inter(
                            size: 9,
                            weight: FontWeight.w500,
                            color: DashboardColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      label: 'Correct',
                      value: '$_correct',
                      color: DashboardColors.success,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _StatRow(
                      label: 'Incorrect',
                      value: '${_done - _correct}',
                      color: DashboardColors.danger,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _StatRow(
                      label: 'Remaining',
                      value: '${topic.totalQuestions - _done}',
                      color: DashboardColors.textSecondary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── Progress bar ──────────────────────────────────
        const SizedBox(height: 12),
        _GlassContainer(
          isDark: isDark,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completion',
                    style: _inter(
                      size: 13,
                      weight: FontWeight.w600,
                      color: DashboardColors.textPrimary(isDark),
                    ),
                  ),
                  Text(
                    '$_done / ${topic.totalQuestions}',
                    style: _inter(
                      size: 13,
                      weight: FontWeight.w700,
                      color: DashboardColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: doneProgress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : DashboardColors.primary
                              .withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        doneProgress >= 1.0
                            ? DashboardColors.success
                            : DashboardColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // ── Stepper: Questions Done ──────────────────────
        const SizedBox(height: 16),
        _SectionLabel(label: 'Adjust Progress', isDark: isDark),
        const SizedBox(height: 10),
        _GlassContainer(
          isDark: isDark,
          child: Column(
            children: [
              // Done stepper
              _StepperRow(
                label: 'Questions done',
                value: _done,
                max: topic.totalQuestions,
                isDark: isDark,
                onDecrement: _done > 0 ? () => _updateDone(-1) : null,
                onIncrement: _done < topic.totalQuestions
                    ? () => _updateDone(1)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: DashboardColors.glassBorder(isDark),
                ),
              ),
              // Correct stepper
              _StepperRow(
                label: 'Correct',
                value: _correct,
                max: _done,
                isDark: isDark,
                onDecrement:
                    _correct > 0 ? () => _updateCorrect(-1) : null,
                onIncrement:
                    _correct < _done ? () => _updateCorrect(1) : null,
              ),
            ],
          ),
        ),
        // ── Quick-add buttons ───────────────────────────
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GlassActionButton(
                icon: Icons.add_rounded,
                label: '+5 Done',
                color: DashboardColors.primary,
                isDark: isDark,
                onTap: () {
                  final delta = math.min(
                      5, topic.totalQuestions - _done);
                  if (delta > 0) _updateDone(delta);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassActionButton(
                icon: Icons.check_rounded,
                label: '+5 Correct',
                color: DashboardColors.success,
                isDark: isDark,
                onTap: () {
                  final delta = math.min(5, _done - _correct);
                  if (delta > 0) _updateCorrect(delta);
                },
              ),
            ),
          ],
        ),
        // ── Save button ────────────────────────────────
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            widget.app
                .updateUWorldProgress(topic.id!, _done, _correct);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Progress saved')),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DashboardColors.primary,
                      DashboardColors.primaryViolet,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.primary
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Save Progress',
                    style: _inter(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// NOTES TAB
// ══════════════════════════════════════════════════════════════════

class _NotesTab extends StatefulWidget {
  final String itemId;
  final String itemType;
  final AppProvider app;
  final bool isDark;

  const _NotesTab({
    required this.itemId,
    required this.itemType,
    required this.app,
    required this.isDark,
  });

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  List<LibraryNote>? _notes;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await widget.app.getLibraryNotes(widget.itemId);
    if (mounted) {
      setState(() => _notes = notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    if (_notes == null) {
      return Center(
        child: CircularProgressIndicator(
          color: DashboardColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _notes!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : DashboardColors.primary
                                  .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DashboardColors.glassBorder(isDark),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.note_alt_rounded,
                          size: 28,
                          color:
                              DashboardColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: _inter(
                          size: 14,
                          weight: FontWeight.w500,
                          color: DashboardColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap below to add your first note',
                        style: _inter(
                          size: 12,
                          weight: FontWeight.w400,
                          color: DashboardColors.textSecondary
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  itemCount: _notes!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final note = _notes![i];
                    return _GlassNoteCard(note: note, isDark: isDark);
                  },
                ),
        ),
        // ── Add Note Button ───────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: DashboardColors.glassBorder(isDark),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: _GlassActionButton(
                icon: Icons.add_rounded,
                label: 'Add Note / Attachment',
                color: DashboardColors.primary,
                isDark: isDark,
                onTap: () async {
                  final added = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => AddNoteSheet(
                      itemId: widget.itemId,
                      itemType: widget.itemType,
                      app: widget.app,
                    ),
                  );
                  if (added == true) {
                    _loadNotes();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ══════════════════════════════════════════════════════════════════

class _BreadcrumbChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color? color;

  const _BreadcrumbChip({
    required this.label,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? DashboardColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: _inter(
          size: 10,
          weight: FontWeight.w600,
          color: c,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: _inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: color,
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

class _GlassTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final bool isDark;

  const _GlassTabBar({
    required this.controller,
    required this.tabs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DashboardColors.glassBorder(isDark),
          width: 0.5,
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: isDark
              ? DashboardColors.primary.withValues(alpha: 0.2)
              : DashboardColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: DashboardColors.primary.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: DashboardColors.primary,
        unselectedLabelColor: DashboardColors.textSecondary,
        labelStyle: _inter(size: 12, weight: FontWeight.w600),
        unselectedLabelStyle: _inter(size: 12, weight: FontWeight.w500),
        tabs: tabs.map((t) => Tab(text: t, height: 36)).toList(),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _GlassContainer({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DashboardColors.glassBorder(isDark),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: DashboardColors.verticalAccentGradient(),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: _inter(
            size: 11,
            weight: FontWeight.w700,
            color: DashboardColors.primary.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: _inter(
            size: 12,
            weight: FontWeight.w500,
            color: DashboardColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: _inter(
            size: 14,
            weight: FontWeight.w700,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final bool isDark;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.max,
    required this.isDark,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: _inter(
            size: 14,
            weight: FontWeight.w500,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        Row(
          children: [
            _StepperButton(
              icon: Icons.remove,
              onTap: onDecrement,
              isDark: isDark,
            ),
            SizedBox(
              width: 48,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: _inter(
                  size: 18,
                  weight: FontWeight.w700,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),
            ),
            _StepperButton(
              icon: Icons.add,
              onTap: onIncrement,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _StepperButton({
    required this.icon,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? DashboardColors.primary.withValues(alpha: isDark ? 0.15 : 0.1)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? DashboardColors.primary.withValues(alpha: 0.3)
                : DashboardColors.glassBorder(isDark),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? DashboardColors.primary
              : DashboardColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _GlassNoteCard extends StatelessWidget {
  final LibraryNote note;
  final bool isDark;

  const _GlassNoteCard({required this.note, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DashboardColors.glassBorder(isDark),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.noteText.isNotEmpty)
                Text(
                  note.noteText,
                  style: _inter(
                    size: 13,
                    weight: FontWeight.w400,
                    color: DashboardColors.textPrimary(isDark),
                  ),
                ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tags
                      .map((t) => _BreadcrumbChip(
                            label: t,
                            isDark: isDark,
                            color: DashboardColors.primary,
                          ))
                      .toList(),
                ),
              ],
              if (note.attachmentPaths.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.attachmentPaths.map((path) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            DashboardColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DashboardColors.warning
                              .withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attachment_rounded,
                              size: 12, color: DashboardColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            path.split('/').last,
                            style: _inter(
                              size: 10,
                              weight: FontWeight.w500,
                              color: DashboardColors.warning,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS & HELPERS
// ══════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    if (progress > 0) {
      const startAngle = -1.5708;
      final sweepAngle = 2 * 3.14159265 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

TextStyle _inter({
  required double size,
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? letterSpacing,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
