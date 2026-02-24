// =============================================================
// MentorMessageBubble — chat bubble for user & mentor messages
// User: right-aligned, primary colour, no avatar.
// Mentor: left-aligned, surface colour with border, 🤖 avatar.
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/models/mentor_message.dart';

class MentorMessageBubble extends StatelessWidget {
  final MentorMessage message;

  const MentorMessageBubble({super.key, required this.message});

  bool get _isUser => message.role == 'user';

  String get _timeLabel {
    final dt = DateTime.tryParse(message.timestamp);
    if (dt == null) return '';
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left:   _isUser ? 48 : 0,
        right:  _isUser ? 0 : 48,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Mentor avatar ────────────────────────────────────
          if (!_isUser) ...[
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
          ],

          // ── Bubble ───────────────────────────────────────────
          Flexible(
            child: Column(
              crossAxisAlignment: _isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isUser
                        ? cs.primary
                        : cs.surface,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(_isUser ? 16 : 4),
                      bottomRight: Radius.circular(_isUser ? 4 : 16),
                    ),
                    border: _isUser
                        ? null
                        : Border.all(
                            color: cs.onSurface.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset:     const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _isUser ? cs.onPrimary : cs.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
