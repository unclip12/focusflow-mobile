// =============================================================
// PersistentAiChatWidget — Floating toggle icon for AI Chat
// Tap to open chat as overlay. Tap again to close.
// =============================================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/models/ai_chat.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/screens/ai_chat/ai_chat_screen.dart';

class PersistentAiChatWidget extends StatefulWidget {
  const PersistentAiChatWidget({super.key});

  /// Other parts of the app can trigger this to programmatically open the chat.
  static final ValueNotifier<bool> expandChatNotifier = ValueNotifier(false);

  @override
  State<PersistentAiChatWidget> createState() => _PersistentAiChatWidgetState();
}

class _PersistentAiChatWidgetState extends State<PersistentAiChatWidget>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(20, 100);
  bool _isChatOpen = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    PersistentAiChatWidget.expandChatNotifier.addListener(_onExpandRequested);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    PersistentAiChatWidget.expandChatNotifier.removeListener(_onExpandRequested);
    super.dispose();
  }

  void _onExpandRequested() {
    if (PersistentAiChatWidget.expandChatNotifier.value && !_isChatOpen && mounted) {
      PersistentAiChatWidget.expandChatNotifier.value = false;
      _openChat();
    }
  }

  Future<void> _openChat() async {
    if (_isChatOpen) return;

    setState(() => _isChatOpen = true);

    // Find the most recent conversation, or create a new one
    final db = DatabaseService.instance;
    final conversations = await db.getConversations();
    String conversationId;

    if (conversations.isNotEmpty) {
      conversationId = conversations.first['id'] as String;
    } else {
      conversationId = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      await db.insertConversation(AiConversation(
        id: conversationId,
        title: 'New Chat',
        createdAt: now,
        updatedAt: now,
      ).toJson());
    }

    if (!mounted) return;

    // Open the chat screen as a full-screen overlay
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AiChatScreen(conversationId: conversationId);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );

    // When the user presses back / closes the chat, update state
    if (mounted) {
      setState(() => _isChatOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxDx = size.width - 60;
    final maxDy = size.height - 60;

    final clamped = Offset(
      _position.dx.clamp(0.0, maxDx.clamp(0.0, double.infinity)),
      _position.dy.clamp(0.0, maxDy.clamp(0.0, double.infinity)),
    );

    return Positioned(
      left: clamped.dx,
      top: clamped.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(0.0, maxDx.clamp(0.0, double.infinity)),
              (_position.dy + details.delta.dy).clamp(0.0, maxDy.clamp(0.0, double.infinity)),
            );
          });
        },
        onTap: () {
          if (_isChatOpen) {
            Navigator.of(context).maybePop();
          } else {
            _openChat();
          }
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.06);
            return Transform.scale(
              scale: _isChatOpen ? 1.0 : scale,
              child: child,
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isChatOpen
                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isChatOpen
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF6366F1))
                      .withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isChatOpen ? Icons.close_rounded : Icons.smart_toy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
