// =============================================================
// MentorScreen — AI Mentor chat UI
// AppScaffold + chat messages list + suggestion bar + input bar.
// resizeToAvoidBottomInset: true (keyboard push-up).
// Send → AppProvider.addMentorMessage(user) → mock mentor reply
// after 800ms delay.
// =============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/mentor_message.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/mentor/mentor_message_bubble.dart';
import 'package:focusflow_mobile/screens/mentor/mentor_suggestions_bar.dart';

// ── Canned mentor replies (rotated) ──────────────────────────────
const _kMentorReplies = [
  "Great question! Based on your recent study logs, I'd recommend focusing on Anatomy — you haven't reviewed it in 5 days.",
  "You're doing amazing! Your streak is strong 🔥. Keep the momentum going with a quick revision session today.",
  "Looking at your analytics, your weakest area is Pharmacology. Want me to create a focused study plan for it?",
  "Here's a tip: try the Pomodoro technique — 25 min study, 5 min break. It works wonders for retention!",
  "Your block completion rate has been improving! You've gone from 65% to 82% this week. Excellent progress!",
  "I notice you study best in the morning. Consider scheduling your hardest subjects before noon.",
  "Don't forget — 3 KB pages are due for revision today. Spaced repetition is key to long-term memory!",
];

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key});

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _uuid        = const Uuid();
  final _focusNode   = FocusNode();
  int   _replyIndex  = 0;
  bool  _isTyping    = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Auto-scroll to bottom ──────────────────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  // ── Send message ───────────────────────────────────────────────
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final app = context.read<AppProvider>();

    // 1. Add user message
    final userMsg = MentorMessage(
      id:        _uuid.v4(),
      role:      'user',
      text:      text,
      timestamp: DateTime.now().toIso8601String(),
    );
    await app.addMentorMessage(userMsg);
    _scrollToBottom();

    // 2. Show typing indicator
    setState(() => _isTyping = true);

    // 3. Mock mentor reply after delay
    await Future.delayed(const Duration(milliseconds: 800));

    final reply = _kMentorReplies[_replyIndex % _kMentorReplies.length];
    _replyIndex++;

    final mentorMsg = MentorMessage(
      id:        _uuid.v4(),
      role:      'model',
      text:      reply,
      timestamp: DateTime.now().toIso8601String(),
    );
    await app.addMentorMessage(mentorMsg);

    if (mounted) {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  // ── Suggestion chip tapped → fill input ────────────────────────
  void _onSuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final messages = app.mentorMessages;

    // Auto-scroll when messages change
    _scrollToBottom();

    return AppScaffold(
      screenName: 'AI Mentor',
      actions: [
        // Clear chat button
        if (messages.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
            onPressed: () => _confirmClear(context, app),
            tooltip: 'Clear chat',
          ),
      ],
      body: Column(
        children: [
          // ── Messages list ──────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    itemCount: messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == messages.length && _isTyping) {
                        return _TypingIndicator();
                      }
                      return MentorMessageBubble(message: messages[i]);
                    },
                  ),
          ),

          // ── Suggestions bar (shown when input is empty) ────────
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (_, value, __) {
              if (value.text.isNotEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MentorSuggestionsBar(onSelect: _onSuggestion),
              );
            },
          ),

          // ── Input bar ────────────────────────────────────────
          _InputBar(
            controller: _controller,
            focusNode:  _focusNode,
            onSend:     _send,
            isTyping:   _isTyping,
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Delete all messages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              app.clearMentorMessages();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// INPUT BAR
// ══════════════════════════════════════════════════════════════════

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final VoidCallback          onSend;
  final bool                  isTyping;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 8, 8,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color:        cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller:  controller,
                focusNode:   focusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines:    4,
                minLines:    1,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText:  'Ask your mentor…',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                  border:    InputBorder.none,
                  isDense:   true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              final hasText = value.text.trim().isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width:  42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasText && !isTyping
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    size:  20,
                    color: hasText && !isTyping
                        ? cs.onPrimary
                        : cs.onSurface.withValues(alpha: 0.3),
                  ),
                  onPressed: hasText && !isTyping ? onSend : null,
                  padding:   EdgeInsets.zero,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// EMPTY CHAT STATE
// ══════════════════════════════════════════════════════════════════

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  80,
              height: 80,
              decoration: BoxDecoration(
                color:  cs.primary.withValues(alpha: 0.08),
                shape:  BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'FocusFlow AI Mentor',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask me about your study plan, weak areas,\nor anything about FMGE prep!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color:  cs.onSurface.withValues(alpha: 0.45),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TYPING INDICATOR
// ══════════════════════════════════════════════════════════════════

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              color:  cs.primary.withValues(alpha: 0.12),
              shape:  BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          // Dots
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:        cs.surface,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(16),
                topRight:    Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft:  Radius.circular(4),
              ),
              border: Border.all(
                  color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Padding(
                padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                child: _AnimatedDot(delay: i * 200),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>  _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width:  7,
        height: 7,
        decoration: BoxDecoration(
          color:  cs.onSurface.withValues(alpha: 0.3),
          shape:  BoxShape.circle,
        ),
      ),
    );
  }
}
