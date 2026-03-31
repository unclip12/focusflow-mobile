// =============================================================
// AddTaskSheet — two paths: Study OR General/Life Task
// General path: categories (cooking, eating, etc.), autocomplete,
//               AM/PM time pickers, event toggle, duration calc.
// Study path: unchanged exam-aware multi-step flow.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/focus_batch_calculator.dart';
import 'planned_insert_conflict_sheet.dart';

// ── General task categories ──────────────────────────────────────
// ── Study task type enums (unchanged) ───────────────────────────
enum ExamType { usmle, fmge }

enum _TaskPath { study, general }

enum UsmleTaskType {
  faPages,
  videoLecture,
  qbankSession,
  ankiReview,
  revision,
  other
}

enum FmgeTaskType {
  cerebellumLecture,
  fmgeQbank,
  subjectReading,
  revision,
  other
}

// ── Chip data ────────────────────────────────────────────────────
class _TaskTypeChip {
  final String label;
  final IconData icon;
  const _TaskTypeChip(this.label, this.icon);
}

class _GeneralTaskCategory {
  final String label;
  final String emoji;
  final Color color;
  final List<String> suggestions;

  const _GeneralTaskCategory({
    required this.label,
    required this.emoji,
    required this.color,
    required this.suggestions,
  });
}

const _generalTaskCategories = <_GeneralTaskCategory>[
  _GeneralTaskCategory(
    label: 'Meal',
    emoji: '🍽️',
    color: Color(0xFFF97316),
    suggestions: [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Snack',
      'Cook lunch',
      'Meal prep',
      'Cook dinner',
      'Make tea',
    ],
  ),
  _GeneralTaskCategory(
    label: 'Exercise',
    emoji: '🏋️',
    color: Color(0xFFEF4444),
    suggestions: [
      'Morning walk',
      'Gym',
      'Workout',
      'Jogging',
      'Stretching',
      'Yoga',
      'Push-ups',
      'Running',
    ],
  ),
  _GeneralTaskCategory(
    label: 'Chores',
    emoji: '🧹',
    color: Color(0xFF14B8A6),
    suggestions: [
      'Wash clothes',
      'Wash dishes',
      'Clean room',
      'Sweep floor',
      'Vacuum',
      'Do laundry',
      'Iron clothes',
      'Take out trash',
    ],
  ),
  _GeneralTaskCategory(
    label: 'Personal',
    emoji: '🛁',
    color: Color(0xFF8B5CF6),
    suggestions: [
      'Shower',
      'Get ready',
      'Morning routine',
      'Evening routine',
      'Skincare',
      'Brush teeth',
    ],
  ),
  _GeneralTaskCategory(
    label: 'Errands',
    emoji: '🚗',
    color: Color(0xFF3B82F6),
    suggestions: [
      'Grocery shopping',
      'Bank',
      'Doctor visit',
      'Pharmacy',
      'Pay bills',
    ],
  ),
  _GeneralTaskCategory(
    label: 'Social',
    emoji: '👥',
    color: Color(0xFFEC4899),
    suggestions: [
      'Call family',
      'Call friend',
      'Family time',
      'Meet friend',
      'Video call',
    ],
  ),
  _GeneralTaskCategory(
    label: 'Rest',
    emoji: '🛌',
    color: Color(0xFF6366F1),
    suggestions: [
      'Nap',
      'Rest',
      'Power nap',
      'Relax',
      'Read for fun',
      'Watch TV',
    ],
  ),
  _GeneralTaskCategory(
    label: 'Other',
    emoji: '⚡',
    color: Color(0xFF64748B),
    suggestions: [],
  ),
];

const _usmleChips = <UsmleTaskType, _TaskTypeChip>{
  UsmleTaskType.faPages: _TaskTypeChip('FA Pages', Icons.menu_book_rounded),
  UsmleTaskType.videoLecture: _TaskTypeChip('Video Lecture', Icons.play_circle_rounded),
  UsmleTaskType.qbankSession: _TaskTypeChip('Qbank Session', Icons.quiz_rounded),
  UsmleTaskType.ankiReview: _TaskTypeChip('Anki Review', Icons.style_rounded),
  UsmleTaskType.revision: _TaskTypeChip('Revision', Icons.replay_rounded),
  UsmleTaskType.other: _TaskTypeChip('Other', Icons.more_horiz_rounded),
};

const _fmgeChips = <FmgeTaskType, _TaskTypeChip>{
  FmgeTaskType.cerebellumLecture: _TaskTypeChip('Cerebellum Lecture', Icons.video_library_rounded),
  FmgeTaskType.fmgeQbank: _TaskTypeChip('FMGE Qbank', Icons.quiz_rounded),
  FmgeTaskType.subjectReading: _TaskTypeChip('Subject Reading', Icons.menu_book_rounded),
  FmgeTaskType.revision: _TaskTypeChip('Revision', Icons.replay_rounded),
  FmgeTaskType.other: _TaskTypeChip('Other', Icons.more_horiz_rounded),
};

// ═══════════════════════════════════════════════════════════════
// AddTaskSheet
// ═══════════════════════════════════════════════════════════════
class AddTaskSheet extends StatefulWidget {
  final String dateKey;
  final TimeOfDay? prefillStartTime;
  final TimeOfDay? prefillEndTime;
  final String? prefillCategory;
  final bool showEventToggle;

  const AddTaskSheet({
    super.key,
    required this.dateKey,
    this.prefillStartTime,
    this.prefillEndTime,
    this.prefillCategory,
    this.showEventToggle = true,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  static const _uuid = Uuid();
  int _step = 0;
  _TaskPath? _taskPath;
  bool _seededDefaultTimes = false;

  // ── Top-level path ──────────────────────────────────────
  // null = not chosen yet, 'study' or 'general'
  String? _path;

  // ── Study path state ─────────────────────────────────
  ExamType? _exam;
  UsmleTaskType? _usmleType;
  FmgeTaskType? _fmgeType;
  _GeneralTaskCategory? _selectedGeneralCategory;

  final _pageCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _deckCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();
  final _cardsCtrl = TextEditingController();

  String? _selectedSystem;
  String? _selectedSubject;
  String? _selectedSource;
  String? _selectedPlatform;
  String _studyMode = 'full';
  final List<String> _selectedSubtopics = [];
  final List<String> _selectedRevisionPages = [];
  bool _isRevision = false;
  Map<String, dynamic>? _trackerInfo;

  // ── General path state ──────────────────────────────
  final _generalTitleCtrl = TextEditingController();
  final _generalNotesCtrl = TextEditingController();
  bool _isEvent = false;

  // ── Shared ───────────────────────────────────────────
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.prefillStartTime;
    _endTime = widget.prefillEndTime;
    if (widget.prefillCategory == 'Revision') {
      _taskPath = _TaskPath.study;
      _exam = ExamType.usmle;
      _usmleType = UsmleTaskType.revision;
      _step = 3;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededDefaultTimes) return;
    _seededDefaultTimes = true;
    if (_startTime != null || _endTime != null) return;

    final app = context.read<AppProvider>();
    final requestedStartMinutes = _defaultRequestedStartMinutes();
    final recommendedStartMinutes = app.recommendedStartMinutesForInsertion(
      widget.dateKey,
      requestedStartMinutes: requestedStartMinutes,
      durationMinutes: 60,
    );
    final endMinutes = (recommendedStartMinutes + 60).clamp(0, 23 * 60 + 59);
    _startTime = TimeOfDay(
      hour: recommendedStartMinutes ~/ 60,
      minute: recommendedStartMinutes % 60,
    );
    _endTime = TimeOfDay(
      hour: endMinutes ~/ 60,
      minute: endMinutes % 60,
    );
  }

  @override
  void dispose() {
    _pageCtrl.removeListener(_onPageNumberChanged);
    _pageCtrl.dispose(); _topicCtrl.dispose(); _titleCtrl.dispose();
    _notesCtrl.dispose(); _deckCtrl.dispose(); _durationCtrl.dispose();
    _questionCtrl.dispose(); _cardsCtrl.dispose();
    _generalTitleCtrl.dispose(); _generalNotesCtrl.dispose();
    super.dispose();
  }

  // ── Autocomplete for general tasks ──────────────────────
  void _onPageNumberChanged() {
    final text = _pageCtrl.text.trim();
    if (text.isEmpty) { if (_trackerInfo != null) setState(() => _trackerInfo = null); return; }
    final pageNum = int.tryParse(text.split('-').first.trim());
    if (pageNum == null) return;
    final app = context.read<AppProvider>();
    final pageIdx = app.faPages.indexWhere((p) => p.pageNum == pageNum);
    if (pageIdx < 0) { setState(() => _trackerInfo = null); return; }
    final page = app.faPages[pageIdx];
    final subtopics = app.getSubtopicsForPage(pageNum);
    final readSubs = subtopics.where((s) => s.status != 'unread').length;
    setState(() {
      _trackerInfo = {
        'pageNum': pageNum, 'subject': page.subject, 'system': page.system,
        'title': page.title, 'status': page.status,
        'revisionCount': page.revisionCount, 'lastRevisedAt': page.lastRevisedAt,
        'firstReadAt': page.firstReadAt, 'subtopics': subtopics,
        'readCount': readSubs, 'totalSubs': subtopics.length,
      };
      _isRevision = page.status != 'unread';
      _selectedSystem ??= page.system;
    });
  }

  // ── Time formatting ───────────────────────────────────
  String _fmt12(TimeOfDay? t) {
    if (t == null) return '– : –';
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final suffix = t.hour < 12 ? 'AM' : 'PM';
    return '$h12:${t.minute.toString().padLeft(2, '0')} $suffix';
  }

  String _fmtHHMM(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _defaultRequestedStartMinutes() {
    final selectedDate = DateTime.tryParse(widget.dateKey);
    final now = DateTime.now();
    if (selectedDate != null &&
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day) {
      return (now.hour * 60) + now.minute;
    }
    return 9 * 60;
  }

  int get _durationMinutes {
    if (_startTime == null || _endTime == null) return 0;
    final s = _startTime!.hour * 60 + _startTime!.minute;
    final e = _endTime!.hour * 60 + _endTime!.minute;
    return e > s ? e - s : 0;
  }

  // ── Save general task ────────────────────────────────
  // ── Save study task (unchanged logic) ─────────────────
  String get _studyTaskTitle {
    if (_exam == ExamType.usmle) {
      switch (_usmleType) {
        case UsmleTaskType.faPages: return 'FA Pages ${_pageCtrl.text}'.trim();
        case UsmleTaskType.videoLecture: return _topicCtrl.text.isNotEmpty ? _topicCtrl.text : 'Video Lecture';
        case UsmleTaskType.qbankSession: return 'Qbank ${_selectedPlatform ?? ''} ${_questionCtrl.text}Q'.trim();
        case UsmleTaskType.ankiReview: return 'Anki ${_deckCtrl.text}'.trim();
        case UsmleTaskType.revision: return 'Revision (${_selectedRevisionPages.length} pages)';
        case UsmleTaskType.other: return _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Study Task';
        case null: return 'Study Task';
      }
    } else {
      switch (_fmgeType) {
        case FmgeTaskType.cerebellumLecture: return 'Cerebellum ${_topicCtrl.text}'.trim();
        case FmgeTaskType.fmgeQbank: return 'FMGE Qbank ${_selectedPlatform ?? ''} ${_questionCtrl.text}Q'.trim();
        case FmgeTaskType.subjectReading: return '${_selectedSubject ?? ''} ${_topicCtrl.text}'.trim();
        case FmgeTaskType.revision: return 'FMGE Revision (${_selectedRevisionPages.length} pages)';
        case FmgeTaskType.other: return _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'FMGE Task';
        case null: return 'FMGE Task';
      }
    }
  }

  BlockType get _studyBlockType {
    if (_exam == ExamType.usmle) {
      switch (_usmleType) {
        case UsmleTaskType.faPages: return BlockType.revisionFa;
        case UsmleTaskType.videoLecture: return BlockType.video;
        case UsmleTaskType.qbankSession: return BlockType.qbank;
        case UsmleTaskType.ankiReview: return BlockType.anki;
        case UsmleTaskType.revision: return BlockType.revisionFa;
        case UsmleTaskType.other: return BlockType.other;
        case null: return BlockType.other;
      }
    } else {
      switch (_fmgeType) {
        case FmgeTaskType.cerebellumLecture: return BlockType.video;
        case FmgeTaskType.fmgeQbank: return BlockType.qbank;
        case FmgeTaskType.subjectReading: return BlockType.other;
        case FmgeTaskType.revision: return BlockType.fmgeRevision;
        case FmgeTaskType.other: return BlockType.other;
        case null: return BlockType.other;
      }
    }
  }

  List<FocusBatch> get _focusBatches {
    if (_startTime == null || _endTime == null) return [];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
    var end = DateTime(now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    return calculateFocusBatches(start, end);
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? TimeOfDay.now());
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickTime12Hour(bool isStart) async {
    final initial = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? TimeOfDay.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  int? get _generalDurationMinutes {
    if (_startTime == null || _endTime == null) return null;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes <= startMinutes) return null;
    return endMinutes - startMinutes;
  }

  List<String> get _generalAutocompleteOptions {
    final query = _titleCtrl.text.trim().toLowerCase();
    final app = context.read<AppProvider>();
    final baseSuggestions = _selectedGeneralCategory != null
        ? _selectedGeneralCategory!.suggestions
        : _generalTaskCategories
            .expand((category) => category.suggestions)
            .toList(growable: false);
    final options = <String>[
      ...baseSuggestions,
      ...app.savedGeneralTaskNames,
    ];

    final seen = <String>{};
    return options.where((option) {
      final normalized = option.trim();
      if (normalized.isEmpty) return false;
      final key = normalized.toLowerCase();
      if (!seen.add(key)) return false;
      if (query.isEmpty) return true;
      return key.contains(query);
    }).take(8).toList(growable: false);
  }

  void _goToPathSelector() {
    setState(() {
      _step = 0;
      _taskPath = null;
    });
  }

  void _openStudyPath() {
    setState(() {
      _taskPath = _TaskPath.study;
      _step = 1;
    });
  }

  void _openGeneralPath() {
    setState(() {
      _taskPath = _TaskPath.general;
      _step = 1;
    });
  }

  Future<void> _saveGeneralTask() async {
    final title = _titleCtrl.text.trim();
    final category = _selectedGeneralCategory;
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a category'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final app = context.read<AppProvider>();
    app.saveGeneralTaskName(title);

    final durationMinutes = _generalDurationMinutes ?? 0;
    final block = Block(
      id: _uuid.v4(),
      index: 0,
      date: widget.dateKey,
      plannedStartTime:
          _startTime != null ? _fmtHHMM(_startTime!) : '00:00',
      plannedEndTime: _endTime != null ? _fmtHHMM(_endTime!) : '00:00',
      type: BlockType.other,
      title: '${category.emoji} $title',
      description:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      plannedDurationMinutes: durationMinutes,
      isEvent: _isEvent,
      status: BlockStatus.notStarted,
    );
    final inserted = await insertPlannedBlocksWithConflictHandling(
      context: context,
      dateKey: widget.dateKey,
      requestedBlocks: [block],
    );
    if (!inserted) return;

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$title" added to timeline'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    // ── Validation: FA Pages requires page number ──────────────
    if (_exam == ExamType.usmle && _usmleType == UsmleTaskType.faPages) {
      if (_pageCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a page number for FA Pages')),
        );
        return;
      }
    }
    if (!mounted) return;

    final batches = _focusBatches;
    final title = _studyTaskTitle;
    final blockType = _studyBlockType;
    final newBlocks = <Block>[];
    final timeFormat = DateFormat('HH:mm');

    if (_startTime == null || _endTime == null) {
      newBlocks.add(Block(
        id: _uuid.v4(), index: 0, date: widget.dateKey,
        plannedStartTime: '00:00', plannedEndTime: '00:00',
        type: blockType, title: title,
        plannedDurationMinutes: 0, isEvent: false, status: BlockStatus.notStarted,
      ));
    } else if (batches.isEmpty) {
      newBlocks.add(Block(
        id: _uuid.v4(), index: 0, date: widget.dateKey,
        plannedStartTime: _fmtHHMM(_startTime!),
        plannedEndTime: _fmtHHMM(_endTime!),
        type: blockType, title: title,
        plannedDurationMinutes: _durationMinutes,
        isEvent: false, status: BlockStatus.notStarted,
      ));
    } else {
      for (int i = 0; i < batches.length; i++) {
        final b = batches[i];
        newBlocks.add(Block(
          id: _uuid.v4(), index: newBlocks.length,
          date: widget.dateKey,
          plannedStartTime: timeFormat.format(b.startTime),
          plannedEndTime: timeFormat.format(b.endTime),
          type: b.isBreak ? BlockType.breakBlock : blockType,
          title: b.isBreak ? '${b.label} (${b.durationMinutes}m)' : title,
          plannedDurationMinutes: b.durationMinutes,
          isEvent: false, status: BlockStatus.notStarted,
        ));
      }
    }

    final inserted = await insertPlannedBlocksWithConflictHandling(
      context: context,
      dateKey: widget.dateKey,
      requestedBlocks: newBlocks,
    );
    if (!inserted) return;

    if (mounted) {
      Navigator.of(context).pop();
      final focusCount = newBlocks.where((b) => b.type != BlockType.breakBlock).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task added with $focusCount focus block${focusCount == 1 ? '' : 's'}')),
      );
    }
  }

  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom + 20;

    final headerTitle = _step == 0
        ? 'Add a task'
        : _taskPath == _TaskPath.general
            ? 'General task'
            : _step == 1
                ? 'What are you studying today?'
                : _step == 2
                    ? 'Choose task type'
                    : 'Task details';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_path != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: _goToPathSelector,
                    ),
                  Expanded(
                    child: Text(
                      headerTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: _step == 0 ? TextAlign.center : TextAlign.left,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCurrentStep(theme, cs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme, ColorScheme cs) {
    if (_step == 0) {
      return _buildPathSelector(theme, cs);
    }
    if (_taskPath == _TaskPath.general) {
      return _buildGeneralTaskForm(theme, cs);
    }
    if (_step == 1) {
      return _buildExamSelector(theme, cs);
    }
    if (_step == 2) {
      return _buildTaskTypeSelector(theme, cs);
    }
    return _buildDetailForm(theme, cs);
  }

  Widget _buildPathSelector(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: _PathCard(
              emoji: '📚',
              label: 'Study Task',
              subtitle: 'Continue to exam and study-task setup',
              color: const Color(0xFF6366F1),
              onTap: _openStudyPath,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _PathCard(
              emoji: '🍽️',
              label: 'General Task',
              subtitle: 'Add life, health, rest, and errand blocks',
              color: const Color(0xFFF97316),
              onTap: _openGeneralPath,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamSelector(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: _ExamCard(
              label: 'USMLE Step 1', icon: Icons.school_rounded,
              color: const Color(0xFF6366F1),
              onTap: () => setState(() {
                _exam = ExamType.usmle;
                _step = 2;
              }),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ExamCard(
              label: 'FMGE', icon: Icons.local_hospital_rounded,
              color: const Color(0xFF10B981),
              onTap: () => setState(() {
                _exam = ExamType.fmge;
                _step = 2;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeSelector(ThemeData theme, ColorScheme cs) {
    if (_exam == ExamType.usmle) {
      return _buildChipList<UsmleTaskType>(
        theme,
        cs,
        chips: _usmleChips,
        selected: _usmleType,
        onSelect: (t) => setState(() {
          _usmleType = t;
          _step = 3;
        }),
      );
    } else {
      return _buildChipList<FmgeTaskType>(
        theme,
        cs,
        chips: _fmgeChips,
        selected: _fmgeType,
        onSelect: (t) => setState(() {
          _fmgeType = t;
          _step = 3;
        }),
      );
    }
  }

  Widget _buildGeneralTaskForm(ThemeData theme, ColorScheme cs) {
    final selectedCategoryColor = _selectedGeneralCategory?.color ?? cs.primary;
    final suggestions = _generalAutocompleteOptions;
    final durationMinutes = _generalDurationMinutes;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _generalTaskCategories.map((category) {
              final isSelected = category == _selectedGeneralCategory;
              return FilterChip(
                label: Text('${category.emoji} ${category.label}'),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedGeneralCategory = category;
                }),
                selectedColor: category.color.withValues(alpha: 0.16),
                checkmarkColor: category.color,
                labelStyle: TextStyle(
                  color: isSelected ? category.color : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: isSelected
                      ? category.color
                      : cs.outline.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Task name',
              hintText: 'What do you need to do?',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border:
                    Border.all(color: cs.outline.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(12),
                color: cs.surfaceContainerLowest,
              ),
              child: Column(
                children: suggestions.map((suggestion) {
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.bolt_rounded,
                        size: 18, color: selectedCategoryColor),
                    title: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () => setState(() {
                      _titleCtrl.text = suggestion;
                      _titleCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: _titleCtrl.text.length),
                      );
                    }),
                  );
                }).toList(),
              ),
            ),
          ],
          if (widget.showEventToggle) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isEvent
                      ? const Color(0xFFEF4444)
                      : cs.outline.withValues(alpha: 0.25),
                ),
                borderRadius: BorderRadius.circular(14),
                color: _isEvent
                    ? const Color(0xFFEF4444).withValues(alpha: 0.06)
                    : cs.surfaceContainerLowest,
              ),
              child: SwitchListTile(
                value: _isEvent,
                onChanged: (value) => setState(() => _isEvent = value),
                title: const Text('Fixed Event'),
                subtitle: _isEvent
                    ? const Text("Scheduler won't move this block")
                    : const Text('Keep this block pinned to the chosen time'),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _generalTimeButton(
                  label: 'Start time',
                  time: _startTime,
                  color: selectedCategoryColor,
                  onTap: () => _pickTime12Hour(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _generalTimeButton(
                  label: 'End time',
                  time: _endTime,
                  color: selectedCategoryColor,
                  onTap: () => _pickTime12Hour(false),
                ),
              ),
            ],
          ),
          if (durationMinutes != null) ...[
            const SizedBox(height: 10),
            Text(
              'Duration: ${_formatDuration(durationMinutes)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _field(
            label: 'Notes',
            hint: 'Optional notes…',
            controller: _notesCtrl,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveGeneralTask,
              style: FilledButton.styleFrom(
                backgroundColor: selectedCategoryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipList<T>(
    ThemeData theme,
    ColorScheme cs, {
    required Map<T, _TaskTypeChip> chips,
    required T? selected,
    required void Function(T) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Wrap(
        spacing: 10, runSpacing: 10,
        children: chips.entries.map((e) {
          final isSelected = e.key == selected;
          return ActionChip(
            avatar: Icon(e.value.icon, size: 18,
                color: isSelected ? cs.onPrimary : cs.primary),
            label: Text(e.value.label),
            backgroundColor: isSelected ? cs.primary : cs.surface,
            labelStyle: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurface,
                fontWeight: FontWeight.w600, fontSize: 13),
            side: BorderSide(
                color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onPressed: () => onSelect(e.key),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailForm(ThemeData theme, ColorScheme cs) {
    final fields = <Widget>[];
    if (_exam == ExamType.usmle) {
      switch (_usmleType) {
        case UsmleTaskType.faPages: fields.addAll(_buildFaPagesFields(cs)); break;
        case UsmleTaskType.videoLecture: fields.addAll(_buildVideoFields(cs, isUsmle: true)); break;
        case UsmleTaskType.qbankSession: fields.addAll(_buildQbankFields(cs, isUsmle: true)); break;
        case UsmleTaskType.ankiReview: fields.addAll(_buildAnkiFields(cs)); break;
        case UsmleTaskType.revision: fields.addAll(_buildRevisionFields(cs)); break;
        case UsmleTaskType.other: fields.addAll(_buildOtherFields(cs)); break;
        case null: break;
      }
    } else {
      switch (_fmgeType) {
        case FmgeTaskType.cerebellumLecture: fields.addAll(_buildCerebellumFields(cs)); break;
        case FmgeTaskType.fmgeQbank: fields.addAll(_buildQbankFields(cs, isUsmle: false)); break;
        case FmgeTaskType.subjectReading: fields.addAll(_buildSubjectReadingFields(cs)); break;
        case FmgeTaskType.revision: fields.addAll(_buildRevisionFields(cs)); break;
        case FmgeTaskType.other: fields.addAll(_buildOtherFields(cs)); break;
        case null: break;
      }
    }
    fields.addAll(_buildTimePickers(cs));
    final batches = _focusBatches;
    if (batches.isNotEmpty) {
      fields.add(const SizedBox(height: 16));
      fields.add(_buildBatchPreview(theme, cs, batches));
    }
    fields.add(const SizedBox(height: 20));
    fields.add(SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.check_rounded, size: 18),
        label: const Text('Save Task'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ));
    fields.add(const SizedBox(height: 24));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: fields);
  }

  // ── Time picker tile (AM/PM) ───────────────────────────
  Widget _timeTile(String label, TimeOfDay? time, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                Text(_fmt12(time),
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: time != null ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimePickers(ColorScheme cs) {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _timeTile('Start', _startTime, () => _pickTime(true), cs)),
          const SizedBox(width: 12),
          Expanded(child: _timeTile('End', _endTime, () => _pickTime(false), cs)),
        ],
      ),
    ];
  }

  // ── All the unchanged study detail field builders ────────
  List<Widget> _buildFaPagesFields(ColorScheme cs) {
    final app = context.read<AppProvider>();
    return [
      _field(label: 'Page number(s)', hint: 'e.g. 45 or 45-48', controller: _pageCtrl),
      if (_trackerInfo != null) ...[ const SizedBox(height: 12), _buildTrackerInfoCard(cs) ],
      const SizedBox(height: 12),
      _dropdown(label: 'System', value: _selectedSystem, items: kBodySystems,
          onChanged: (v) => setState(() => _selectedSystem = v)),
      const SizedBox(height: 12),
      Text('Study mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.6))),
      const SizedBox(height: 4),
      Row(children: [
        _radioChip('Full page', _studyMode == 'full', () => setState(() => _studyMode = 'full'), cs),
        const SizedBox(width: 8),
        _radioChip('Specific subtopics', _studyMode == 'specific',
            () => setState(() => _studyMode = 'specific'), cs),
      ]),
      if (_studyMode == 'specific') ...[
        const SizedBox(height: 12),
        Builder(builder: (_) {
          if (_trackerInfo != null) {
            final subtopics = _trackerInfo!['subtopics'] as List;
            if (subtopics.isNotEmpty) {
              return Wrap(spacing: 6, runSpacing: 6, children: subtopics.map((s) {
                final name = s.name as String;
                final alreadyRead = s.status != 'unread';
                return FilterChip(
                  label: Text(name, style: TextStyle(fontSize: 12,
                      decoration: alreadyRead ? TextDecoration.lineThrough : null)),
                  selected: _selectedSubtopics.contains(name),
                  onSelected: (sel) => setState(() => sel
                      ? _selectedSubtopics.add(name)
                      : _selectedSubtopics.remove(name)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  avatar: alreadyRead ? const Icon(Icons.check_circle_rounded,
                      size: 14, color: Color(0xFF10B981)) : null,
                );
              }).toList());
            }
          }
          final page = _pageCtrl.text.trim();
          final kbEntry = app.knowledgeBase.cast<KnowledgeBaseEntry?>().firstWhere(
                (e) => e!.pageNumber == page, orElse: () => null);
          final topicNames = kbEntry?.topics.map((t) => t.name).toList() ?? [];
          if (topicNames.isNotEmpty) {
            return Wrap(spacing: 6, runSpacing: 6, children: topicNames.map((t) =>
              FilterChip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                selected: _selectedSubtopics.contains(t),
                onSelected: (sel) => setState(() => sel
                    ? _selectedSubtopics.add(t) : _selectedSubtopics.remove(t)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              )).toList());
          }
          return _field(label: 'Subtopics', hint: 'Enter subtopic names', controller: _topicCtrl);
        }),
      ],
    ];
  }

  Widget _buildTrackerInfoCard(ColorScheme cs) {
    final info = _trackerInfo!;
    final status = info['status'] as String;
    final revCount = info['revisionCount'] as int;
    final readCount = info['readCount'] as int;
    final totalSubs = info['totalSubs'] as int;
    final title = info['title'] as String;
    final subject = info['subject'] as String;
    final system = info['system'] as String;
    final lastRevisedAt = info['lastRevisedAt'] as String?;
    final isStudied = status != 'unread';
    final modeColor = _isRevision ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: modeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: modeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: modeColor),
            const SizedBox(width: 6),
            Expanded(child: Text('Page ${info['pageNum']} — $title',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Text('$subject • $system',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _infoPill(isStudied ? '✅ Already Studied' : '📖 Not Yet Studied',
                isStudied ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
            _infoPill('$readCount/$totalSubs subtopics', cs.primary),
            if (revCount > 0)
              _infoPill('R$revCount revision${revCount > 1 ? 's' : ''}', const Color(0xFF8B5CF6)),
            if (lastRevisedAt != null)
              _infoPill('Last: ${_shortDate(lastRevisedAt)}', cs.onSurface.withValues(alpha: 0.5)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text('Mode: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.6))),
            GestureDetector(
              onTap: () => setState(() => _isRevision = !_isRevision),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: modeColor.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_isRevision ? Icons.replay_rounded : Icons.menu_book_rounded,
                      size: 14, color: modeColor),
                  const SizedBox(width: 4),
                  Text(_isRevision ? 'Revision' : 'First Study',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: modeColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.swap_horiz_rounded, size: 14, color: modeColor.withValues(alpha: 0.5)),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoPill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );

  String _shortDate(String iso) {
    try { final dt = DateTime.parse(iso); return '${dt.day}/${dt.month}'; } catch (_) { return iso; }
  }

  List<Widget> _buildVideoFields(ColorScheme cs, {required bool isUsmle}) {
    final sources = isUsmle
        ? ['Boards & Beyond', 'Sketchy', 'Pathoma', 'Dirty Medicine', 'Ninja Nerd', 'YouTube', 'Other']
        : ['Cerebellum', 'Marrow', 'PrepLadder', 'YouTube', 'Other'];
    return [
      _dropdown(label: 'Source', value: _selectedSource, items: sources,
          onChanged: (v) => setState(() => _selectedSource = v)),
      const SizedBox(height: 12),
      _field(label: 'Topic / Title', hint: 'e.g. Cardiology – Valvular Disease', controller: _topicCtrl),
      const SizedBox(height: 12),
      _dropdown(label: 'System', value: _selectedSystem, items: kBodySystems,
          onChanged: (v) => setState(() => _selectedSystem = v)),
      const SizedBox(height: 12),
      _field(label: 'Duration (minutes)', hint: 'e.g. 45', controller: _durationCtrl, isNumber: true),
    ];
  }

  List<Widget> _buildQbankFields(ColorScheme cs, {required bool isUsmle}) {
    final platforms = isUsmle
        ? ['UWorld', 'Amboss', 'NBME', 'Free120', 'Other']
        : ['Marrow', 'PrepLadder', 'DAMS', 'INICET', 'Other'];
    final systems = isUsmle ? kBodySystems : kFmgeSubjects;
    return [
      _dropdown(label: 'Platform', value: _selectedPlatform, items: platforms,
          onChanged: (v) => setState(() => _selectedPlatform = v)),
      const SizedBox(height: 12),
      _dropdown(label: isUsmle ? 'Subject / System' : 'Subject',
          value: isUsmle ? _selectedSystem : _selectedSubject,
          items: systems,
          onChanged: (v) => setState(() => isUsmle ? _selectedSystem = v : _selectedSubject = v)),
      const SizedBox(height: 12),
      _field(label: 'Number of questions', hint: 'e.g. 40', controller: _questionCtrl, isNumber: true),
    ];
  }

  List<Widget> _buildAnkiFields(ColorScheme cs) => [
    _field(label: 'Deck name', hint: 'e.g. AnKing Step 1', controller: _deckCtrl),
    const SizedBox(height: 12),
    _field(label: 'Estimated cards', hint: 'e.g. 200', controller: _cardsCtrl, isNumber: true),
  ];

  List<Widget> _buildRevisionFields(ColorScheme cs) {
    final app = context.read<AppProvider>();
    final duePages = app.knowledgeBase
        .where((e) => SrsService.isDueNow(nextRevisionAt: e.nextRevisionAt)).toList();
    if (duePages.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24), alignment: Alignment.center,
          child: Column(children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: cs.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No pages due today 🎉', style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
          ]),
        ),
      ];
    }
    return [
      Text('Pages due for revision', style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      ...duePages.map((e) => CheckboxListTile(
        dense: true, contentPadding: EdgeInsets.zero,
        title: Text('Page ${e.pageNumber} – ${e.title}', style: const TextStyle(fontSize: 13)),
        value: _selectedRevisionPages.contains(e.pageNumber),
        onChanged: (v) => setState(() => v == true
            ? _selectedRevisionPages.add(e.pageNumber)
            : _selectedRevisionPages.remove(e.pageNumber)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
    ];
  }

  List<Widget> _buildCerebellumFields(ColorScheme cs) => [
    _dropdown(label: 'Subject', value: _selectedSubject, items: kFmgeSubjects,
        onChanged: (v) => setState(() => _selectedSubject = v)),
    const SizedBox(height: 12),
    _field(label: 'Topic / Lecture name', hint: 'e.g. Anatomy Lec 5', controller: _topicCtrl),
    const SizedBox(height: 12),
    _field(label: 'Duration (minutes)', hint: 'e.g. 60', controller: _durationCtrl, isNumber: true),
  ];

  List<Widget> _buildSubjectReadingFields(ColorScheme cs) => [
    _dropdown(label: 'Subject', value: _selectedSubject, items: kFmgeSubjects,
        onChanged: (v) => setState(() => _selectedSubject = v)),
    const SizedBox(height: 12),
    _field(label: 'Topic', hint: 'e.g. CNS pharmacology', controller: _topicCtrl),
  ];

  List<Widget> _buildOtherFields(ColorScheme cs) => [
    _field(label: 'Title', hint: 'e.g. Review notes', controller: _titleCtrl),
    const SizedBox(height: 12),
    _field(label: 'Notes', hint: 'Optional notes…', controller: _notesCtrl, maxLines: 3),
  ];

  Widget _buildBatchPreview(ThemeData theme, ColorScheme cs, List<FocusBatch> batches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suggested Focus Plan', style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: batches.map((b) {
            final color = b.isBreak ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
            return Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text('${b.label} ${b.durationMinutes}m',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            );
          }).toList()),
        ),
      ],
    );
  }

  Widget _generalTimeButton({
    required String label,
    required TimeOfDay? time,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time != null ? _formatTimeOfDay12Hour(time) : 'Select time',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: time != null ? color : color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeOfDay12Hour(TimeOfDay time) {
    final now = DateTime.now();
    return DateFormat('h:mm a')
        .format(DateTime(now.year, now.month, now.day, time.hour, time.minute));
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}min';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}min';
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _dropdown({required String label, required String? value,
      required List<String> items, required void Function(String?) onChanged}) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      items: items.map((s) => DropdownMenuItem(value: s,
          child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _radioChip(String label, bool selected, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 16, color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.7))),
        ]),
      ),
    );
  }
}

// ================================================================
// Path Card
// ================================================================
// ================================================================
// Exam Card (unchanged)
// ================================================================
class _ExamCard extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _ExamCard({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.18)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 14),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PathCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.18),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
