import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';

class StudyTask {
  final String type;
  final String label;
  final String detail;
  final List<int> pageNumbers;
  final List<int> topicIds;
  final int questionCount;

  const StudyTask({
    required this.type,
    required this.label,
    required this.detail,
    this.pageNumbers = const [],
    this.topicIds = const [],
    this.questionCount = 0,
  });
}

class StudyFlowScreen extends StatefulWidget {
  final String dateKey;
  final VoidCallback? onComplete;
  final List<StudyTask>? queuedTasks;

  const StudyFlowScreen({
    super.key,
    required this.dateKey,
    this.onComplete,
    this.queuedTasks,
  });

  @override
  State<StudyFlowScreen> createState() => _StudyFlowScreenState();
}

class _StudyFlowScreenState extends State<StudyFlowScreen> {
  int _currentPage = 0;
  int _pagesCompletedInSession = 0;
  int _targetPages = 10;
  bool _isStudying = false;
  bool _showAnkiPrompt = false;
  final List<int> _ankiPendingPages = [];
  Timer? _timer;
  int _totalElapsed = 0;
  int _pageElapsed = 0;
  final List<_PageTiming> _pageTimings = [];

  late final List<StudyTask> _queue;
  int _currentTaskIndex = 0;
  int _currentTaskPageIndex = 0;

  static const _motivations = [
    'Come on, you got this!',
    'One page closer to your goal!',
    'Future doctor in the making!',
    'Keep the momentum going!',
    'You are doing amazing!',
    'Every page counts!',
    'Stay focused, stay strong!',
    'Almost there, keep pushing!',
    'Your hard work will pay off!',
    'Page by page, you will conquer this!',
  ];

  bool get _hasQueuedTasks => _queue.isNotEmpty;

  StudyTask? get _currentTask {
    if (_currentTaskIndex < 0 || _currentTaskIndex >= _queue.length) {
      return null;
    }
    return _queue[_currentTaskIndex];
  }

  bool get _isQueueFaTask => _currentTask?.type == 'FA';
  bool get _isQueueUWorldTask => _currentTask?.type == 'UWORLD';

  @override
  void initState() {
    super.initState();
    _queue = List<StudyTask>.from(widget.queuedTasks ?? const []);

    final app = context.read<AppProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    settingsProvider.ensureStudyPlanStartDate();

    if (_hasQueuedTasks) {
      _targetPages = _queue
          .where((task) => task.type == 'FA')
          .fold<int>(0, (sum, task) => sum + task.pageNumbers.length);
      _prepareQueuedTask();
    } else {
      _currentPage = app.getNextContinuePage();
      _targetPages = settingsProvider.dailyFAGoal;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prepareQueuedTask() {
    final task = _currentTask;
    if (task == null) {
      return;
    }

    if (task.type == 'FA') {
      _currentTaskPageIndex = 0;
      if (task.pageNumbers.isNotEmpty) {
        _currentPage = task.pageNumbers.first;
      }
    }

    _pageElapsed = 0;
    _showAnkiPrompt = false;
    _ankiPendingPages.clear();
  }

  void _startStudying() {
    setState(() {
      _isStudying = true;
      _pageElapsed = 0;
    });

    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _totalElapsed++;
        _pageElapsed++;
      });
    });
  }

  void _markPageDone() {
    if (_hasQueuedTasks && !_isQueueFaTask) {
      return;
    }

    HapticsService.medium();
    final app = context.read<AppProvider>();

    _pageTimings.add(
      _PageTiming(
        pageNum: _currentPage,
        seconds: _pageElapsed,
      ),
    );

    final subs = app.getSubtopicsForPage(_currentPage);
    if (subs.isNotEmpty) {
      final unreadIds =
          subs.where((s) => s.status == 'unread').map((s) => s.id!).toList();
      if (unreadIds.isNotEmpty) {
        app.markSubtopicsRead(unreadIds);
      }
    }

    app.updateFAPageStatus(_currentPage, 'read');
    _pagesCompletedInSession++;

    if (!_hasQueuedTasks) {
      _ankiPendingPages.add(_currentPage);
      if (_ankiPendingPages.length >= 4) {
        setState(() {
          _showAnkiPrompt = true;
        });
        return;
      }
    }

    _moveToNextPage();
  }

  void _moveToNextPage() {
    if (_hasQueuedTasks && _isQueueFaTask) {
      final pages = _currentTask?.pageNumbers ?? const <int>[];
      final nextIndex = _currentTaskPageIndex + 1;
      if (nextIndex < pages.length) {
        setState(() {
          _currentTaskPageIndex = nextIndex;
          _currentPage = pages[nextIndex];
          _pageElapsed = 0;
        });
        return;
      }
      _advanceQueue();
      return;
    }

    final app = context.read<AppProvider>();
    int next = _currentPage + 1;
    while (true) {
      final match = app.faPages.where((p) => p.pageNum == next).toList();
      if (match.isEmpty || match.first.status == 'unread') {
        break;
      }
      next++;
    }
    setState(() {
      _currentPage = next;
      _pageElapsed = 0;
    });
  }

  void _advanceQueue() {
    final nextTaskIndex = _currentTaskIndex + 1;
    if (nextTaskIndex >= _queue.length) {
      _endSession();
      return;
    }

    setState(() {
      _currentTaskIndex = nextTaskIndex;
      _currentTaskPageIndex = 0;
      _prepareQueuedTask();
    });
  }

  Future<void> _completeQueuedUWorldTask() async {
    if (!_hasQueuedTasks || !_isQueueUWorldTask) {
      return;
    }

    HapticsService.medium();
    final app = context.read<AppProvider>();
    final task = _currentTask;
    if (task == null) {
      return;
    }

    for (final topicId in task.topicIds.toSet()) {
      await app.markUWorldTopicDone(topicId);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _pageElapsed = 0;
    });
    _advanceQueue();
  }

  void _doAnki() {
    final app = context.read<AppProvider>();
    for (final page in _ankiPendingPages) {
      app.updateFAPageStatus(page, 'anki_done');
    }
    setState(() {
      _showAnkiPrompt = false;
      _ankiPendingPages.clear();
    });
    _moveToNextPage();
  }

  void _skipAnki() {
    setState(() {
      _showAnkiPrompt = false;
      _ankiPendingPages.clear();
    });
    _moveToNextPage();
  }

  void _endSession() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isStudying = false);
    widget.onComplete?.call();
    Navigator.pop(context);
  }

  String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  List<UWorldTopic> _selectedUWorldTopics(AppProvider app) {
    final selectedIds = _currentTask?.topicIds.toSet() ?? const <int>{};
    if (selectedIds.isEmpty) {
      return const <UWorldTopic>[];
    }

    final topics = app.uworldTopics
        .where((topic) => topic.id != null && selectedIds.contains(topic.id))
        .toList()
      ..sort((a, b) {
        final systemCompare = a.system.compareTo(b.system);
        if (systemCompare != 0) {
          return systemCompare;
        }
        return a.subtopic.compareTo(b.subtopic);
      });
    return topics;
  }

  String _welcomeDescription() {
    final task = _currentTask;
    if (!_hasQueuedTasks || task == null) {
      return _currentPage > 1
          ? 'You have completed up to page ${_currentPage - 1}.\nContinue from page $_currentPage?'
          : 'Start studying from page $_currentPage';
    }

    if (task.type == 'FA') {
      if (task.pageNumbers.isEmpty) {
        return 'Queued task ${_currentTaskIndex + 1} of ${_queue.length}.';
      }
      final first = task.pageNumbers.first;
      final last = task.pageNumbers.last;
      final range = first == last ? 'page $first' : 'pages $first-$last';
      return 'Queued task ${_currentTaskIndex + 1} of ${_queue.length}.\nStart FA $range?';
    }

    if (task.type == 'UWORLD') {
      return 'Queued task ${_currentTaskIndex + 1} of ${_queue.length}.\nStart ${task.detail}?';
    }

    return 'Queued task ${_currentTaskIndex + 1} of ${_queue.length}.';
  }

  String _welcomeBadgeText() {
    final task = _currentTask;
    if (!_hasQueuedTasks || task == null) {
      return 'Today\'s target: $_targetPages pages';
    }

    if (task.type == 'FA') {
      final count = task.pageNumbers.length;
      return '$count selected page${count == 1 ? '' : 's'}';
    }

    if (task.type == 'UWORLD') {
      return '${task.questionCount} queued question${task.questionCount == 1 ? '' : 's'}';
    }

    return task.detail;
  }

  String _faBannerText() {
    if (_hasQueuedTasks && _isQueueFaTask) {
      final task = _currentTask!;
      final remaining = task.pageNumbers.length - _currentTaskPageIndex;
      return 'Task ${_currentTaskIndex + 1}/${_queue.length}: $remaining selected page${remaining == 1 ? '' : 's'} left.';
    }

    final remaining = _targetPages - _pagesCompletedInSession;
    final motivation =
        _motivations[_pagesCompletedInSession % _motivations.length];
    return remaining > 0
        ? 'Today\'s target: $remaining pages remaining. $motivation'
        : 'You have hit your target! Amazing!';
  }

  String _faHeaderTitle() {
    if (_hasQueuedTasks && _isQueueFaTask) {
      return '${_currentTask!.label} - Page $_currentPage';
    }
    return 'Page $_currentPage';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();

    if (!_isStudying) {
      return _WelcomeView(
        description: _welcomeDescription(),
        badgeText: _welcomeBadgeText(),
        onStart: _startStudying,
        onBack: () => Navigator.pop(context),
      );
    }

    if (!_hasQueuedTasks && _showAnkiPrompt) {
      return _AnkiPromptView(
        pages: _ankiPendingPages,
        onDoAnki: _doAnki,
        onSkip: _skipAnki,
      );
    }

    if (_hasQueuedTasks && _isQueueUWorldTask) {
      final task = _currentTask!;
      final topics = _selectedUWorldTopics(app);
      return _QueuedUWorldView(
        task: task,
        topics: topics,
        taskIndex: _currentTaskIndex,
        totalTasks: _queue.length,
        totalElapsedLabel: _fmtTime(_totalElapsed),
        taskElapsedLabel: _fmtTime(_pageElapsed),
        onComplete: _completeQueuedUWorldTask,
        onEndSession: _endSession,
      );
    }

    final subtopics = app.getSubtopicsForPage(_currentPage);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _faHeaderTitle(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _endSession,
                    child: const Text('End Session'),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Target',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _faBannerText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: subtopics.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 48,
                            color: cs.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Study Page $_currentPage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No subtopics available for this page',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                'Subtopics',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  final unreadIds = subtopics
                                      .where((s) => s.status == 'unread')
                                      .map((s) => s.id!)
                                      .toList();
                                  if (unreadIds.isNotEmpty) {
                                    app.markSubtopicsRead(unreadIds);
                                  }
                                },
                                icon: const Icon(
                                  Icons.select_all_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Select All',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: subtopics.length,
                            itemBuilder: (context, i) {
                              final sub = subtopics[i];
                              final isDone = sub.status != 'unread';
                              return CheckboxListTile(
                                value: isDone,
                                onChanged: (val) {
                                  if (val == true && sub.id != null) {
                                    app.markSubtopicRead(sub.id!);
                                  }
                                },
                                title: Text(
                                  sub.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isDone
                                        ? cs.onSurface.withValues(alpha: 0.4)
                                        : cs.onSurface,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'This page',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmtTime(_pageElapsed),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        width: 1,
                        height: 40,
                        color: cs.onSurface.withValues(alpha: 0.1),
                      ),
                      Column(
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmtTime(_totalElapsed),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _markPageDone,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Done with this page',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: const Color(0xFF8B5CF6),
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

class _WelcomeView extends StatelessWidget {
  final String description;
  final String badgeText;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const _WelcomeView({
    required this.description,
    required this.badgeText,
    required this.onStart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to Study?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text(
                    'Let\'s Go!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueuedUWorldView extends StatelessWidget {
  final StudyTask task;
  final List<UWorldTopic> topics;
  final int taskIndex;
  final int totalTasks;
  final String totalElapsedLabel;
  final String taskElapsedLabel;
  final Future<void> Function() onComplete;
  final VoidCallback onEndSession;

  const _QueuedUWorldView({
    required this.task,
    required this.topics,
    required this.taskIndex,
    required this.totalTasks,
    required this.totalElapsedLabel,
    required this.taskElapsedLabel,
    required this.onComplete,
    required this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.quiz_rounded,
                    size: 22,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onEndSession,
                    child: const Text('End Session'),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    const Color(0xFFF97316).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.playlist_add_check_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Task ${taskIndex + 1}/$totalTasks - ${task.questionCount} queued questions',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  task.detail,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: topics.isEmpty
                  ? Center(
                      child: Text(
                        'No UWorld topics were selected.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        final remaining =
                            topic.totalQuestions - topic.doneQuestions;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.quiz_rounded,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.subtopic,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${topic.system} - $remaining remaining',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'This task',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            taskElapsedLabel,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        width: 1,
                        height: 40,
                        color: cs.onSurface.withValues(alpha: 0.1),
                      ),
                      Column(
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalElapsedLabel,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Complete UWorld task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
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

class _AnkiPromptView extends StatelessWidget {
  final List<int> pages;
  final VoidCallback onDoAnki;
  final VoidCallback onSkip;

  const _AnkiPromptView({
    required this.pages,
    required this.onDoAnki,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pageRange = pages.isNotEmpty
        ? 'pages ${pages.first}-${pages.last}'
        : 'recent pages';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('Anki', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Time for Anki!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please complete Anki for $pageRange\nbefore continuing to the next page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onDoAnki,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Done with Anki',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip Anki for now',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageTiming {
  final int pageNum;
  final int seconds;
  const _PageTiming({required this.pageNum, required this.seconds});
}
