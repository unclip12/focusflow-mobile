import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';

class StudyFlowScreen extends StatefulWidget {
  final String dateKey;
  final VoidCallback? onComplete;

  const StudyFlowScreen({
    super.key,
    required this.dateKey,
    this.onComplete,
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

  static const _motivations = [
    'Come on, you got this! 💪',
    'One page closer to your goal! 🎯',
    'Future doctor in the making! 🩺',
    'Keep the momentum going! 🚀',
    'You\'re doing amazing! ⭐',
    'Every page counts! 📖',
    'Stay focused, stay strong! 🔥',
    'Almost there, keep pushing! 🏆',
    'Your hard work will pay off! 💎',
    'Page by page, you\'ll conquer this! 🗻',
  ];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    // Gap-aware: find first unread page in book order
    _currentPage = app.getNextContinuePage();
    _targetPages = settingsProvider.dailyFAGoal;
    // Auto-set study plan start date on first study session
    settingsProvider.ensureStudyPlanStartDate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStudying() {
    setState(() {
      _isStudying = true;
      _pageElapsed = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _totalElapsed++;
          _pageElapsed++;
        });
      }
    });
  }

  void _markPageDone() {
    HapticsService.medium();
    final app = context.read<AppProvider>();

    // Record timing
    _pageTimings.add(_PageTiming(
      pageNum: _currentPage,
      seconds: _pageElapsed,
    ));

    // Mark subtopics as read
    final subs = app.getSubtopicsForPage(_currentPage);
    if (subs.isNotEmpty) {
      final unreadIds = subs
          .where((s) => s.status == 'unread')
          .map((s) => s.id!)
          .toList();
      if (unreadIds.isNotEmpty) {
        app.markSubtopicsRead(unreadIds);
      }
    }

    // Update FA page status
    app.updateFAPageStatus(_currentPage, 'read');

    _pagesCompletedInSession++;
    _ankiPendingPages.add(_currentPage);

    // Check if Anki prompt needed (every 4 pages)
    if (_ankiPendingPages.length >= 4) {
      setState(() {
        _showAnkiPrompt = true;
      });
      return;
    }

    _moveToNextPage();
  }

  void _moveToNextPage() {
    // Gap-aware: skip already-read pages
    final app = context.read<AppProvider>();
    int next = _currentPage + 1;
    while (true) {
      final match = app.faPages.where((p) => p.pageNum == next).toList();
      if (match.isEmpty || match.first.status == 'unread') break;
      next++;
    }
    setState(() {
      _currentPage = next;
      _pageElapsed = 0;
    });
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
    setState(() => _isStudying = false);
    widget.onComplete?.call();
    Navigator.pop(context);
  }

  String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();

    if (!_isStudying) {
      return _WelcomeView(
        currentPage: _currentPage,
        targetPages: _targetPages,
        pagesCompleted: _pagesCompletedInSession,
        onStart: _startStudying,
        onBack: () => Navigator.pop(context),
      );
    }

    if (_showAnkiPrompt) {
      return _AnkiPromptView(
        pages: _ankiPendingPages,
        onDoAnki: _doAnki,
        onSkip: _skipAnki,
      );
    }

    final subtopics = app.getSubtopicsForPage(_currentPage);
    final remaining = _targetPages - _pagesCompletedInSession;
    final motivation = _motivations[_pagesCompletedInSession % _motivations.length];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Page $_currentPage',
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

            // ── Progress banner ───────────────────────────────
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
                  Text(
                    '🎯',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remaining > 0
                          ? 'Today\'s target: $remaining pages remaining. $motivation'
                          : 'You\'ve hit your target! Amazing! 🎉',
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

            // ── Subtopics checklist ───────────────────────────
            Expanded(
              child: subtopics.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 48,
                              color: cs.primary.withValues(alpha: 0.3)),
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
                                icon: const Icon(Icons.select_all_rounded, size: 16),
                                label: const Text('Select All', style: TextStyle(fontSize: 12)),
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
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    color: isDone
                                        ? cs.onSurface.withValues(alpha: 0.4)
                                        : cs.onSurface,
                                  ),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
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

            // ── Timer + Done button ───────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text('This page', style: TextStyle(
                            fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5),
                          )),
                          const SizedBox(height: 2),
                          Text(_fmtTime(_pageElapsed), style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700,
                            fontFamily: 'monospace', color: const Color(0xFF8B5CF6),
                          )),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        width: 1, height: 40,
                        color: cs.onSurface.withValues(alpha: 0.1),
                      ),
                      Column(
                        children: [
                          Text('Total', style: TextStyle(
                            fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5),
                          )),
                          const SizedBox(height: 2),
                          Text(_fmtTime(_totalElapsed), style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700,
                            fontFamily: 'monospace', color: cs.onSurface.withValues(alpha: 0.6),
                          )),
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
                      label: const Text('Done with this page',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

// ── Welcome View ────────────────────────────────────────────────
class _WelcomeView extends StatelessWidget {
  final int currentPage;
  final int targetPages;
  final int pagesCompleted;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const _WelcomeView({
    required this.currentPage,
    required this.targetPages,
    required this.pagesCompleted,
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
              Icon(Icons.menu_book_rounded, size: 64,
                  color: const Color(0xFF8B5CF6)),
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
                currentPage > 1
                    ? 'You\'ve completed up to page ${currentPage - 1}.\nContinue from page $currentPage?'
                    : 'Start studying from page $currentPage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🎯 Today\'s target: $targetPages pages',
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
                  label: const Text("Let's Go!",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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

// ── Anki Prompt View ────────────────────────────────────────────
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
        ? 'pages ${pages.first}–${pages.last}'
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
                  child: Text('🃏', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Time for Anki! 🎴',
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
                  label: const Text('Done with Anki',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

// ── Page Timing Record ──────────────────────────────────────────
class _PageTiming {
  final int pageNum;
  final int seconds;
  const _PageTiming({required this.pageNum, required this.seconds});
}
