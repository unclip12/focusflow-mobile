// =============================================================
// PersistentAiChatWidget — Floating toggle icon for AI Chat
// Tap to open chat as overlay. Tap again to close.
// =============================================================

import 'package:flutter/material.dart';

import 'package:focusflow_mobile/app_router.dart';

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

    if (!mounted) return;

    // Open the chat list screen using the global appRouter
    try {
      await appRouter.pushNamed(Routes.aiChat);
    } catch (e) {
      debugPrint('Error pushing aiChat: $e');
    }

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
            appRouter.pop();
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
