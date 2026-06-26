// =============================================================
// AiChatScreen — Full ChatGPT-style conversation interface
// =============================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/models/ai_chat.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/services/ai/local_llm_service.dart';

class AiChatScreen extends StatefulWidget {
  final String conversationId;

  const AiChatScreen({super.key, required this.conversationId});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  final _db = DatabaseService.instance;
  final _llm = LocalLlmService();
  bool _isTyping = false;
  String _title = 'New Chat';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final rows = await _db.getChatMessages(widget.conversationId);
    final convRows = await _db.getConversations();
    final conv = convRows.firstWhere(
      (c) => c['id'] == widget.conversationId,
      orElse: () => <String, dynamic>{},
    );
    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(rows.map((r) => AiChatMessage.fromJson(r)));
        _title = conv['title'] as String? ?? 'New Chat';
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text, {String type = 'text'}) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    final userMsg = AiChatMessage(
      id: const Uuid().v4(),
      conversationId: widget.conversationId,
      role: 'user',
      content: text.trim(),
      type: type,
      timestamp: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    // Persist user message
    await _db.insertChatMessage(userMsg.toJson());

    // Update conversation
    final now = DateTime.now().toIso8601String();
    final displayTitle = _title == 'New Chat' && _messages.length <= 1
        ? (text.trim().length > 40 ? '${text.trim().substring(0, 40)}...' : text.trim())
        : _title;
    await _db.updateConversation(widget.conversationId, {
      'updatedAt': now,
      'lastMessage': text.trim().length > 100 ? '${text.trim().substring(0, 100)}...' : text.trim(),
      'title': displayTitle,
    });
    if (displayTitle != _title) {
      setState(() => _title = displayTitle);
    }

    // Generate AI response
    try {
      final response = await _llm.generateResponse(text.trim());
      final aiMsg = AiChatMessage(
        id: const Uuid().v4(),
        conversationId: widget.conversationId,
        role: 'ai',
        content: response,
        timestamp: DateTime.now().toIso8601String(),
      );

      if (mounted) {
        setState(() {
          _messages.add(aiMsg);
          _isTyping = false;
        });
        _scrollToBottom();
      }

      // Persist AI message
      await _db.insertChatMessage(aiMsg.toJson());
      await _db.updateConversation(widget.conversationId, {
        'updatedAt': DateTime.now().toIso8601String(),
        'lastMessage': response.length > 100 ? '${response.substring(0, 100)}...' : response,
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(AiChatMessage(
            id: const Uuid().v4(),
            conversationId: widget.conversationId,
            role: 'ai',
            content: 'Error: $e',
            timestamp: DateTime.now().toIso8601String(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final ext = result.files.single.extension?.toLowerCase();
    final fileName = result.files.single.name;

    setState(() => _isTyping = true);

    try {
      String extractedText = '';
      if (ext == 'pdf') {
        final doc = PdfDocument(inputBytes: await file.readAsBytes());
        extractedText = PdfTextExtractor(doc).extractText();
        doc.dispose();
      } else {
        final inputImage = InputImage.fromFile(file);
        final recognizer = TextRecognizer();
        final recognized = await recognizer.processImage(inputImage);
        extractedText = recognized.text;
        recognizer.close();
      }

      if (extractedText.isNotEmpty) {
        await _sendMessage(
          'I am attaching "$fileName". Here is the text:\n"""$extractedText"""\n\nPlease analyze this.',
          type: 'attachment',
        );
      } else {
        if (mounted) {
          setState(() {
            _messages.add(AiChatMessage(
              id: const Uuid().v4(),
              conversationId: widget.conversationId,
              role: 'ai',
              content: 'I could not extract any text from that file.',
              timestamp: DateTime.now().toIso8601String(),
            ));
            _isTyping = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(AiChatMessage(
            id: const Uuid().v4(),
            conversationId: widget.conversationId,
            role: 'ai',
            content: 'Error reading attachment: $e',
            timestamp: DateTime.now().toIso8601String(),
          ));
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index], isDark);
                    },
                  ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTypingIndicator(isDark),
              ),
            ),

          // Input bar
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.smart_toy_rounded,
            size: 64,
            color: isDark ? const Color(0xFF6366F1) : const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 16),
          Text(
            'FocusFlow AI',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal study assistant.\nAsk me anything about your studies!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message, bool isDark) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == 'attachment')
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file, size: 14,
                        color: isUser ? Colors.white70 : (isDark ? Colors.white38 : Colors.black38)),
                    const SizedBox(width: 4),
                    Text('Attachment',
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser ? Colors.white70 : (isDark ? Colors.white38 : Colors.black38),
                        )),
                  ],
                ),
              ),
            if (message.type == 'voice')
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, size: 14,
                        color: isUser ? Colors.white70 : (isDark ? Colors.white38 : Colors.black38)),
                    const SizedBox(width: 4),
                    Text('Voice message',
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser ? Colors.white70 : (isDark ? Colors.white38 : Colors.black38),
                        )),
                  ],
                ),
              ),
            SelectableText(
              message.content,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isUser ? Colors.white : (isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypingDot(delay: 0, isDark: isDark),
          const SizedBox(width: 4),
          _TypingDot(delay: 150, isDark: isDark),
          const SizedBox(width: 4),
          _TypingDot(delay: 300, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0E1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: Icon(Icons.attach_file_rounded,
                color: isDark ? Colors.white38 : Colors.black38),
            onPressed: _isTyping ? null : _pickAttachment,
          ),

          // Mic button
          IconButton(
            icon: Icon(Icons.mic_rounded,
                color: isDark ? Colors.white38 : Colors.black38),
            onPressed: _isTyping ? null : () {
              // TODO: Implement voice recording with record package + AssemblyAI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input coming soon! Please configure AssemblyAI key in Settings.')),
              );
            },
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Message FocusFlow AI...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (text) => _sendMessage(text),
            ),
          ),
          const SizedBox(width: 4),

          // Send button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: (_controller.text.trim().isNotEmpty && !_isTyping)
                  ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                  : null,
              color: (_controller.text.trim().isEmpty || _isTyping)
                  ? (isDark ? Colors.white12 : Colors.grey[300])
                  : null,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              onPressed: _isTyping ? null : () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated typing dot for the AI thinking indicator.
class _TypingDot extends StatefulWidget {
  final int delay;
  final bool isDark;

  const _TypingDot({required this.delay, required this.isDark});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isDark ? Colors.white54 : Colors.black38,
            ),
          ),
        );
      },
    );
  }
}
