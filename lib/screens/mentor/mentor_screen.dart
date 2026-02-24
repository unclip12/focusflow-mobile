// =============================================================
// MentorScreen — JSON paste receiver for KB import
// Accepts pasted JSON from FA extraction prompts, detects valid
// KB JSON format, and imports pages into the Knowledge Base.
// Non-JSON messages get a static helper response.
// =============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/mentor_message.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/mentor/mentor_message_bubble.dart';
import 'package:focusflow_mobile/screens/mentor/mentor_suggestions_bar.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key});

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _uuid       = const Uuid();
  final _focusNode  = FocusNode();

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

  // ── Try to parse text as KB JSON ───────────────────────────────
  /// Returns parsed list if valid KB JSON, null otherwise.
  List<Map<String, dynamic>>? _tryParseAsKBJson(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List || decoded.isEmpty) return null;

      final first = decoded[0];
      if (first is! Map<String, dynamic>) return null;

      // Must have pageNumber, title, and topics keys
      if (!first.containsKey('pageNumber') ||
          !first.containsKey('title') ||
          !first.containsKey('topics')) {
        return null;
      }

      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ── Show KB import bottom sheet ────────────────────────────────
  void _showImportSheet(List<Map<String, dynamic>> pages) {
    final pageNumbers = pages
        .map((p) => p['pageNumber']?.toString() ?? '?')
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import to Knowledge Base',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Found ${pages.length} page(s): ${pageNumbers.join(', ')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _importPages(pages);
                      },
                      child: const Text('Add to Knowledge Base'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Import parsed pages into KB ────────────────────────────────
  Future<void> _importPages(List<Map<String, dynamic>> pages) async {
    final app = context.read<AppProvider>();

    for (final item in pages) {
      // Build topics as TrackableItem list from JSON
      List<TrackableItem> topicsList = [];
      if (item['topics'] != null) {
        if (item['topics'] is List) {
          topicsList = (item['topics'] as List).map((t) {
            if (t is Map<String, dynamic>) {
              return TrackableItem.fromJson(t);
            }
            // If topic is a plain string, wrap it
            return TrackableItem(
              id: const Uuid().v4(),
              name: t.toString(),
              revisionCount: 0,
              currentRevisionIndex: 0,
              logs: [],
            );
          }).toList();
        }
      }

      // Build keyPoints list
      List<String>? keyPointsList;
      if (item['keyPoints'] != null) {
        if (item['keyPoints'] is List) {
          keyPointsList = (item['keyPoints'] as List)
              .map((k) => k.toString())
              .toList();
        }
      }

      final entry = KnowledgeBaseEntry(
        pageNumber: item['pageNumber']?.toString() ?? '',
        title: item['title']?.toString() ?? '',
        system: item['system']?.toString() ?? 'General',
        subject: item['subject']?.toString() ?? 'General',
        revisionCount: 0,
        currentRevisionIndex: 0,
        ankiTotal: 0,
        ankiCovered: 0,
        videoLinks: [],
        tags: [],
        notes: '',
        keyPoints: keyPointsList,
        logs: [],
        topics: topicsList,
      );

      await app.upsertKBEntry(entry);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${pages.length} page(s) added to Knowledge Base'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Send message ───────────────────────────────────────────────
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Step A: Try to parse as KB JSON
    final parsed = _tryParseAsKBJson(text);

    if (parsed != null) {
      // Step B: Show import bottom sheet (do NOT save as chat message)
      _controller.clear();
      _showImportSheet(parsed);
      return;
    }

    // Step D: Not KB JSON — show as normal message with static response
    final app = context.read<AppProvider>();
    _controller.clear();

    // Add user message
    final userMsg = MentorMessage(
      id:        _uuid.v4(),
      role:      'user',
      text:      text,
      timestamp: DateTime.now().toIso8601String(),
    );
    await app.addMentorMessage(userMsg);
    _scrollToBottom();

    // Static mentor response
    final mentorMsg = MentorMessage(
      id:        _uuid.v4(),
      role:      'model',
      text:      "I'm your study assistant. Paste your structured FA JSON output "
                 "here and I'll import it directly into your Knowledge Base.",
      timestamp: DateTime.now().toIso8601String(),
    );
    await app.addMentorMessage(mentorMsg);

    if (mounted) {
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
    final app      = context.watch<AppProvider>();
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
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5)),
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
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
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

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
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
                  hintText:  'Paste JSON here or ask a question…',
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
                  color: hasText
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    size:  20,
                    color: hasText
                        ? cs.onPrimary
                        : cs.onSurface.withValues(alpha: 0.3),
                  ),
                  onPressed: hasText ? onSend : null,
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
                child: Text('📋', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Paste FA JSON Output Here',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Copy the structured output from Gemini/ChatGPT\n'
              'after using your FA extraction prompt,\n'
              'then paste it here.',
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
