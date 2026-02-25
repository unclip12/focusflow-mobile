// =============================================================
// AddTaskSheet – multi-step exam-aware task creation flow
// Step 1: Exam selector (USMLE Step 1 / FMGE)
// Step 2: Task type selector (horizontal chips)
// Step 3: Detail form with focus batch preview
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

// ── Task type enums ──────────────────────────────────────────────
enum ExamType { usmle, fmge }

enum UsmleTaskType { faPages, videoLecture, qbankSession, ankiReview, revision, other }
enum FmgeTaskType { cerebellumLecture, fmgeQbank, subjectReading, revision, other }

// ── Chip data ────────────────────────────────────────────────────
class _TaskTypeChip {
  final String label;
  final IconData icon;
  const _TaskTypeChip(this.label, this.icon);
}

const _usmleChips = <UsmleTaskType, _TaskTypeChip>{
  UsmleTaskType.faPages:       _TaskTypeChip('FA Pages', Icons.menu_book_rounded),
  UsmleTaskType.videoLecture:  _TaskTypeChip('Video Lecture', Icons.play_circle_rounded),
  UsmleTaskType.qbankSession:  _TaskTypeChip('Qbank Session', Icons.quiz_rounded),
  UsmleTaskType.ankiReview:    _TaskTypeChip('Anki Review', Icons.style_rounded),
  UsmleTaskType.revision:      _TaskTypeChip('Revision', Icons.replay_rounded),
  UsmleTaskType.other:         _TaskTypeChip('Other', Icons.more_horiz_rounded),
};

const _fmgeChips = <FmgeTaskType, _TaskTypeChip>{
  FmgeTaskType.cerebellumLecture: _TaskTypeChip('Cerebellum Lecture', Icons.video_library_rounded),
  FmgeTaskType.fmgeQbank:         _TaskTypeChip('FMGE Qbank', Icons.quiz_rounded),
  FmgeTaskType.subjectReading:    _TaskTypeChip('Subject Reading', Icons.menu_book_rounded),
  FmgeTaskType.revision:          _TaskTypeChip('Revision', Icons.replay_rounded),
  FmgeTaskType.other:             _TaskTypeChip('Other', Icons.more_horiz_rounded),
};

// ═══════════════════════════════════════════════════════════════
// AddTaskSheet widget
// ═══════════════════════════════════════════════════════════════

class AddTaskSheet extends StatefulWidget {
  final String dateKey; // YYYY-MM-DD
  const AddTaskSheet({super.key, required this.dateKey});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  static const _uuid = Uuid();
  int _step = 0; // 0 = exam, 1 = task type, 2 = details

  // ── Selections ──────────────────────────────────────────────
  ExamType? _exam;
  UsmleTaskType? _usmleType;
  FmgeTaskType? _fmgeType;

  // ── Form controllers ────────────────────────────────────────
  final _pageCtrl       = TextEditingController();
  final _topicCtrl      = TextEditingController();
  final _titleCtrl      = TextEditingController();
  final _notesCtrl      = TextEditingController();
  final _deckCtrl       = TextEditingController();
  final _durationCtrl   = TextEditingController();
  final _questionCtrl   = TextEditingController();
  final _cardsCtrl      = TextEditingController();

  String? _selectedSystem;
  String? _selectedSubject;
  String? _selectedSource;
  String? _selectedPlatform;
  String _studyMode = 'full'; // 'full' | 'specific'
  final List<String> _selectedSubtopics = [];
  final List<String> _selectedRevisionPages = [];

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _topicCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _deckCtrl.dispose();
    _durationCtrl.dispose();
    _questionCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  // ── Computed ────────────────────────────────────────────────
  String get _taskTitle {
    if (_exam == ExamType.usmle) {
      switch (_usmleType) {
        case UsmleTaskType.faPages:
          return 'FA Pages \${_pageCtrl.text}'.trim();
        case UsmleTaskType.videoLecture:
          return _topicCtrl.text.isNotEmpty ? _topicCtrl.text : 'Video Lecture';
        case UsmleTaskType.qbankSession:
          return 'Qbank \${_selectedPlatform ?? ''} \${_questionCtrl.text}Q'.trim();
        case UsmleTaskType.ankiReview:
          return 'Anki \${_deckCtrl.text}'.trim();
        case UsmleTaskType.revision:
          return 'Revision (\${_selectedRevisionPages.length} pages)';
        case UsmleTaskType.other:
          return _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Study Task';
        case null:
          return 'Study Task';
      }
    } else {
      switch (_fmgeType) {
        case FmgeTaskType.cerebellumLecture:
          return 'Cerebellum \${_topicCtrl.text}'.trim();
        case FmgeTaskType.fmgeQbank:
          return 'FMGE Qbank \${_selectedPlatform ?? ''} \${_questionCtrl.text}Q'.trim();
        case FmgeTaskType.subjectReading:
          return '\${_selectedSubject ?? ''} \${_topicCtrl.text}'.trim();
        case FmgeTaskType.revision:
          return 'FMGE Revision (\${_selectedRevisionPages.length} pages)';
        case FmgeTaskType.other:
          return _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'FMGE Task';
        case null:
          return 'FMGE Task';
      }
    }
  }

  BlockType get _blockType {
    if (_exam == ExamType.usmle) {
      switch (_usmleType) {
        case UsmleTaskType.faPages:      return BlockType.revisionFa;
        case UsmleTaskType.videoLecture: return BlockType.video;
        case UsmleTaskType.qbankSession: return BlockType.qbank;
        case UsmleTaskType.ankiReview:   return BlockType.anki;
        case UsmleTaskType.revision:     return BlockType.revisionFa;
        case UsmleTaskType.other:        return BlockType.other;
        case null:                       return BlockType.other;
      }
    } else {
      switch (_fmgeType) {
        case FmgeTaskType.cerebellumLecture: return BlockType.video;
        case FmgeTaskType.fmgeQbank:         return BlockType.qbank;
        case FmgeTaskType.subjectReading:    return BlockType.other;
        case FmgeTaskType.revision:          return BlockType.fmgeRevision;
        case FmgeTaskType.other:             return BlockType.other;
        case null:                           return BlockType.other;
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

  // ── Time picker ──────────────────────────────────────────────
  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? TimeOfDay.now());
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() {
        if (isStart) { _startTime = picked; } else { _endTime = picked; }
      });
    }
  }

  // ── Save ────────────────────────────────────────────────────
  Future<void> _save() async {
    final app = context.read<AppProvider>();
    final batches = _focusBatches;
    final title = _taskTitle;

    DayPlan? existing = app.getDayPlan(widget.dateKey);
    final existingBlocks = List<Block>.from(existing?.blocks ?? []);
    final newBlocks = <Block>[];
    final timeFormat = DateFormat('HH:mm');

    if (_startTime == null || _endTime == null) {
      newBlocks.add(Block(
        id: _uuid.v4(),
        index: existingBlocks.length,
        date: widget.dateKey,
        plannedStartTime: '00:00',
        plannedEndTime: '00:00',
        type: _blockType,
        title: title,
        plannedDurationMinutes: 0,
        status: BlockStatus.notStarted,
      ));
    } else if (batches.isEmpty) {
      newBlocks.add(Block(
        id: _uuid.v4(),
        index: existingBlocks.length,
        date: widget.dateKey,
        plannedStartTime: _formatTimeOfDay(_startTime!),
        plannedEndTime: _formatTimeOfDay(_endTime!),
        type: _blockType,
        title: title,
        plannedDurationMinutes: _endTime!.hour * 60 + _endTime!.minute -
            (_startTime!.hour * 60 + _startTime!.minute),
        status: BlockStatus.notStarted,
      ));
    } else {
      for (int i = 0; i < batches.length; i++) {
        final b = batches[i];
        if (b.isBreak) {
          newBlocks.add(Block(
            id: _uuid.v4(),
            index: existingBlocks.length + newBlocks.length,
            date: widget.dateKey,
            plannedStartTime: timeFormat.format(b.startTime),
            plannedEndTime: timeFormat.format(b.endTime),
            type: BlockType.breakBlock,
            title: '\${b.label} (\${b.durationMinutes}m)',
            plannedDurationMinutes: b.durationMinutes,
            status: BlockStatus.notStarted,
          ));
        } else {
          newBlocks.add(Block(
            id: _uuid.v4(),
            index: existingBlocks.length + newBlocks.length,
            date: widget.dateKey,
            plannedStartTime: timeFormat.format(b.startTime),
            plannedEndTime: timeFormat.format(b.endTime),
            type: _blockType,
            title: title,
            plannedDurationMinutes: b.durationMinutes,
            status: BlockStatus.notStarted,
          ));
        }
      }
    }

    final focusBlockCount = newBlocks.where((b) => b.type != BlockType.breakBlock).length;
    final allBlocks = [...existingBlocks, ...newBlocks];

    final plan = existing?.copyWith(blocks: allBlocks) ?? DayPlan(
      date: widget.dateKey,
      faPages: const [],
      faPagesCount: 0,
      videos: const [],
      notesFromUser: '',
      notesFromAI: '',
      attachments: const [],
      breaks: const [],
      blocks: allBlocks,
      totalStudyMinutesPlanned: allBlocks
          .where((b) => b.type != BlockType.breakBlock)
          .fold<int>(0, (s, b) => s + b.plannedDurationMinutes),
      totalBreakMinutes: allBlocks
          .where((b) => b.type == BlockType.breakBlock)
          .fold<int>(0, (s, b) => s + b.plannedDurationMinutes),
    );

    await app.upsertDayPlan(plan);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task added with \$focusBlockCount focus block\${focusBlockCount == 1 ? '' : 's'}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '\${t.hour.toString().padLeft(2, '0')}:\${t.minute.toString().padLeft(2, '0')}';

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
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
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: () => setState(() => _step--),
                    ),
                  Expanded(
                    child: Text(
                      _step == 0 ? 'What are you studying today?'
                          : _step == 1 ? 'Choose task type'
                          : 'Task details',
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
            const SizedBox(height: 8),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _step == 0
                    ? _buildExamSelector(theme, cs)
                    : _step == 1
                        ? _buildTaskTypeSelector(theme, cs)
                        : _buildDetailForm(theme, cs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 0 – Exam Selector
  // ═══════════════════════════════════════════════════════════

  Widget _buildExamSelector(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: _ExamCard(
              label: 'USMLE Step 1',
              icon: Icons.school_rounded,
              color: const Color(0xFF6366F1),
              onTap: () => setState(() {
                _exam = ExamType.usmle;
                _step = 1;
              }),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ExamCard(
              label: 'FMGE',
              icon: Icons.local_hospital_rounded,
              color: const Color(0xFF10B981),
              onTap: () => setState(() {
                _exam = ExamType.fmge;
                _step = 1;
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 1 – Task Type Selector
  // ═══════════════════════════════════════════════════════════

  Widget _buildTaskTypeSelector(ThemeData theme, ColorScheme cs) {
    if (_exam == ExamType.usmle) {
      return _buildChipList<UsmleTaskType>(
        theme, cs,
        chips: _usmleChips,
        selected: _usmleType,
        onSelect: (t) => setState(() { _usmleType = t; _step = 2; }),
      );
    } else {
      return _buildChipList<FmgeTaskType>(
        theme, cs,
        chips: _fmgeChips,
        selected: _fmgeType,
        onSelect: (t) => setState(() { _fmgeType = t; _step = 2; }),
      );
    }
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.entries.map((e) {
            final isSelected = e.key == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ActionChip(
                avatar: Icon(e.value.icon, size: 18,
                    color: isSelected ? cs.onPrimary : cs.primary),
                label: Text(e.value.label),
                backgroundColor: isSelected ? cs.primary : cs.surface,
                labelStyle: TextStyle(
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: () => onSelect(e.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 2 – Detail Form
  // ═══════════════════════════════════════════════════════════

  Widget _buildDetailForm(ThemeData theme, ColorScheme cs) {
    final fields = <Widget>[];

    if (_exam == ExamType.usmle) {
      switch (_usmleType) {
        case UsmleTaskType.faPages:
          fields.addAll(_buildFaPagesFields(cs));
          break;
        case UsmleTaskType.videoLecture:
          fields.addAll(_buildVideoFields(cs, isUsmle: true));
          break;
        case UsmleTaskType.qbankSession:
          fields.addAll(_buildQbankFields(cs, isUsmle: true));
          break;
        case UsmleTaskType.ankiReview:
          fields.addAll(_buildAnkiFields(cs));
          break;
        case UsmleTaskType.revision:
          fields.addAll(_buildRevisionFields(cs));
          break;
        case UsmleTaskType.other:
          fields.addAll(_buildOtherFields(cs));
          break;
        case null:
          break;
      }
    } else {
      switch (_fmgeType) {
        case FmgeTaskType.cerebellumLecture:
          fields.addAll(_buildCerebellumFields(cs));
          break;
        case FmgeTaskType.fmgeQbank:
          fields.addAll(_buildQbankFields(cs, isUsmle: false));
          break;
        case FmgeTaskType.subjectReading:
          fields.addAll(_buildSubjectReadingFields(cs));
          break;
        case FmgeTaskType.revision:
          fields.addAll(_buildRevisionFields(cs));
          break;
        case FmgeTaskType.other:
          fields.addAll(_buildOtherFields(cs));
          break;
        case null:
          break;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields,
    );
  }

  // ── FA Pages fields ──────────────────────────────────────────
  List<Widget> _buildFaPagesFields(ColorScheme cs) {
    final app = context.read<AppProvider>();
    return [
      _field(label: 'Page number(s)', hint: 'e.g. 45 or 45-48', controller: _pageCtrl),
      const SizedBox(height: 12),
      _dropdown(
        label: 'System',
        value: _selectedSystem,
        items: kBodySystems,
        onChanged: (v) => setState(() => _selectedSystem = v),
      ),
      const SizedBox(height: 12),
      Text('Study mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha:0.6))),
      const SizedBox(height: 4),
      Row(
        children: [
          _radioChip('Full page', _studyMode == 'full', () => setState(() => _studyMode = 'full'), cs),
          const SizedBox(width: 8),
          _radioChip('Specific subtopics', _studyMode == 'specific', () => setState(() => _studyMode = 'specific'), cs),
        ],
      ),
      if (_studyMode == 'specific') ...[
        const SizedBox(height: 12),
        Builder(builder: (_) {
          final page = _pageCtrl.text.trim();
          final kbEntry = app.knowledgeBase.cast<KnowledgeBaseEntry?>().firstWhere(
            (e) => e!.pageNumber == page,
            orElse: () => null,
          );
          final topicNames = kbEntry?.topics.map((t) => t.name).toList() ?? [];
          if (topicNames.isNotEmpty) {
            return Wrap(
              spacing: 6, runSpacing: 6,
              children: topicNames.map((t) => FilterChip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                selected: _selectedSubtopics.contains(t),
                onSelected: (sel) => setState(() {
                  sel ? _selectedSubtopics.add(t) : _selectedSubtopics.remove(t);
                }),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              )).toList(),
            );
          } else {
            return _field(label: 'Subtopics', hint: 'Enter subtopic names', controller: _topicCtrl);
          }
        }),
      ],
    ];
  }

  // ── Video fields ──────────────────────────────────────────────
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

  // ── Qbank fields ──────────────────────────────────────────────
  List<Widget> _buildQbankFields(ColorScheme cs, {required bool isUsmle}) {
    final platforms = isUsmle
        ? ['UWorld', 'Amboss', 'NBME', 'Free120', 'Other']
        : ['Marrow', 'PrepLadder', 'DAMS', 'INICET', 'Other'];
    final systems = isUsmle ? kBodySystems : kFmgeSubjects;
    final systemLabel = isUsmle ? 'Subject / System' : 'Subject';
    return [
      _dropdown(label: 'Platform', value: _selectedPlatform, items: platforms,
          onChanged: (v) => setState(() => _selectedPlatform = v)),
      const SizedBox(height: 12),
      _dropdown(label: systemLabel, value: isUsmle ? _selectedSystem : _selectedSubject,
          items: systems,
          onChanged: (v) => setState(() {
            if (isUsmle) { _selectedSystem = v; } else { _selectedSubject = v; }
          })),
      const SizedBox(height: 12),
      _field(label: 'Number of questions', hint: 'e.g. 40', controller: _questionCtrl, isNumber: true),
    ];
  }

  // ── Anki fields ───────────────────────────────────────────────
  List<Widget> _buildAnkiFields(ColorScheme cs) {
    return [
      _field(label: 'Deck name', hint: 'e.g. AnKing Step 1', controller: _deckCtrl),
      const SizedBox(height: 12),
      _field(label: 'Estimated cards', hint: 'e.g. 200', controller: _cardsCtrl, isNumber: true),
    ];
  }

  // ── Revision fields (due pages from KB) ──────────────────────
  List<Widget> _buildRevisionFields(ColorScheme cs) {
    final app = context.read<AppProvider>();
    final duePages = app.knowledgeBase
        .where((e) => SrsService.isDueNow(nextRevisionAt: e.nextRevisionAt))
        .toList();

    if (duePages.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 48,
                  color: cs.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('No pages due today 🎉',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ];
    }

    return [
      Text('Pages due for revision', style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      ...duePages.map((e) => CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text('Page \${e.pageNumber} – \${e.title}',
            style: const TextStyle(fontSize: 13)),
        value: _selectedRevisionPages.contains(e.pageNumber),
        onChanged: (v) => setState(() {
          if (v == true) {
            _selectedRevisionPages.add(e.pageNumber);
          } else {
            _selectedRevisionPages.remove(e.pageNumber);
          }
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
    ];
  }

  // ── Cerebellum Lecture fields ─────────────────────────────────
  List<Widget> _buildCerebellumFields(ColorScheme cs) {
    return [
      _dropdown(label: 'Subject', value: _selectedSubject, items: kFmgeSubjects,
          onChanged: (v) => setState(() => _selectedSubject = v)),
      const SizedBox(height: 12),
      _field(label: 'Topic / Lecture name', hint: 'e.g. Anatomy Lec 5', controller: _topicCtrl),
      const SizedBox(height: 12),
      _field(label: 'Duration (minutes)', hint: 'e.g. 60', controller: _durationCtrl, isNumber: true),
    ];
  }

  // ── Subject Reading fields ────────────────────────────────────
  List<Widget> _buildSubjectReadingFields(ColorScheme cs) {
    return [
      _dropdown(label: 'Subject', value: _selectedSubject, items: kFmgeSubjects,
          onChanged: (v) => setState(() => _selectedSubject = v)),
      const SizedBox(height: 12),
      _field(label: 'Topic', hint: 'e.g. CNS pharmacology', controller: _topicCtrl),
    ];
  }

  // ── Other fields ──────────────────────────────────────────────
  List<Widget> _buildOtherFields(ColorScheme cs) {
    return [
      _field(label: 'Title', hint: 'e.g. Review notes', controller: _titleCtrl),
      const SizedBox(height: 12),
      _field(label: 'Notes', hint: 'Optional notes…', controller: _notesCtrl, maxLines: 3),
    ];
  }

  // ── Time pickers ──────────────────────────────────────────────
  List<Widget> _buildTimePickers(ColorScheme cs) {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _timeTile('Start time', _startTime, () => _pickTime(true), cs)),
          const SizedBox(width: 12),
          Expanded(child: _timeTile('End time', _endTime, () => _pickTime(false), cs)),
        ],
      ),
    ];
  }

  Widget _timeTile(String label, TimeOfDay? time, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                Text(
                  time != null ? _formatTimeOfDay(time) : '– : –',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: time != null ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Focus batch preview ───────────────────────────────────────
  Widget _buildBatchPreview(ThemeData theme, ColorScheme cs, List<FocusBatch> batches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Focus Plan',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: batches.map((b) {
              final color = b.isBreak
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF6366F1);
              return Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '\${b.label} \${b.durationMinutes}m',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Reusable form helpers
  // ═══════════════════════════════════════════════════════════

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
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
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
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 16, color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Exam Card widget
// ═══════════════════════════════════════════════════════════════

class _ExamCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExamCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.18)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
