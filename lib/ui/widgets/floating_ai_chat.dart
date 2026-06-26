import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../services/ai/local_llm_service.dart';
import '../../widgets/liquid_glass_card.dart';

class PersistentAiChatWidget extends StatefulWidget {
  const PersistentAiChatWidget({super.key});

  static final ValueNotifier<bool> expandChatNotifier = ValueNotifier(false);

  @override
  State<PersistentAiChatWidget> createState() => _PersistentAiChatWidgetState();
}

class _PersistentAiChatWidgetState extends State<PersistentAiChatWidget> {
  static final List<Map<String, String>> _messages = [];
  static final LocalLlmService _llmService = LocalLlmService();
  StreamSubscription<Map<String, String>>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _chatSubscription = _llmService.chatStream.stream.listen((msg) {
      if (mounted) {
        setState(() {
          _messages.add(msg);
        });
      }
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FloatingChatWidget(
      messages: _messages,
      llmService: _llmService,
    );
  }
}

class _FloatingChatWidget extends StatefulWidget {
  final List<Map<String, String>> messages;
  final LocalLlmService llmService;

  const _FloatingChatWidget({
    required this.messages,
    required this.llmService,
  });

  @override
  State<_FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends State<_FloatingChatWidget> {
  Offset position = const Offset(20, 100);
  bool isExpanded = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    PersistentAiChatWidget.expandChatNotifier.addListener(_onExpandRequested);
  }

  @override
  void dispose() {
    PersistentAiChatWidget.expandChatNotifier.removeListener(_onExpandRequested);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onExpandRequested() {
    if (PersistentAiChatWidget.expandChatNotifier.value && !isExpanded && mounted) {
      setState(() {
        isExpanded = true;
      });
      PersistentAiChatWidget.expandChatNotifier.value = false;
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

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final text = _controller.text;
    _controller.clear();
    
    setState(() {
      widget.messages.add({'role': 'user', 'content': text});
      isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await widget.llmService.generateResponse(text);
      if (mounted) {
        setState(() {
          widget.messages.add({'role': 'ai', 'content': response});
          isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          widget.messages.add({'role': 'ai', 'content': 'Error: ${e.toString()}'});
          isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _pickAndProcessAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final ext = result.files.single.extension?.toLowerCase();

    setState(() => isTyping = true);

    try {
      String extractedText = '';
      if (ext == 'pdf') {
        final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        extractedText = extractor.extractText();
        document.dispose();
      } else {
        final inputImage = InputImage.fromFile(file);
        final textRecognizer = TextRecognizer();
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        extractedText = recognizedText.text;
        textRecognizer.close();
      }

      if (extractedText.isNotEmpty) {
        final prompt = 'I am attaching a document/image. Here is the text extracted from it:\n"""$extractedText"""\n\nPlease acknowledge receipt and ask me what I want to do with it.';
        setState(() {
          widget.messages.add({'role': 'user', 'content': '[Attachment: ${result.files.single.name}]'});
        });
        
        final response = await widget.llmService.generateResponse(prompt);
        if (mounted) {
          setState(() {
            widget.messages.add({'role': 'ai', 'content': response});
            isTyping = false;
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) {
          setState(() {
            widget.messages.add({'role': 'ai', 'content': 'I could not extract any text from that file.'});
            isTyping = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          widget.messages.add({'role': 'ai', 'content': 'Error reading attachment: $e'});
          isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final chatWidth = size.width * 0.88 > 340 ? 340.0 : size.width * 0.88;
    final chatHeight = size.height * 0.6 > 480 ? 480.0 : size.height * 0.6;
    final maxDx = size.width - (isExpanded ? chatWidth : 60);
    final maxDy = size.height - (isExpanded ? chatHeight : 60);
    
    final clampedPosition = Offset(
      position.dx.clamp(0.0, maxDx.clamp(0.0, double.infinity)),
      position.dy.clamp(0.0, maxDy.clamp(0.0, double.infinity)),
    );
    
    return Positioned(
      left: clampedPosition.dx,
      top: clampedPosition.dy,
      child: isExpanded
          ? _buildExpandedChat(clampedPosition, maxDx, maxDy, chatWidth, chatHeight)
          : _buildChatHead(clampedPosition, maxDx, maxDy),
    );
  }

  Widget _buildChatHead(Offset currentPos, double maxDx, double maxDy) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          position = Offset(
            (currentPos.dx + details.delta.dx).clamp(0.0, maxDx.clamp(0.0, double.infinity)),
            (currentPos.dy + details.delta.dy).clamp(0.0, maxDy.clamp(0.0, double.infinity)),
          );
        });
      },
      onTap: () {
        setState(() {
          isExpanded = true;
        });
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildExpandedChat(Offset currentPos, double maxDx, double maxDy, double chatWidth, double chatHeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: LiquidGlassCard(
        child: SizedBox(
          width: chatWidth,
          height: chatHeight,
          child: Column(
            children: [
              _buildChatHeader(currentPos, maxDx, maxDy),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.messages[index];
                    final isUser = msg['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: chatWidth * 0.78),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF6366F1)
                              : (isDark ? Colors.white12 : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['content'] ?? '',
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Thinking...",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              _buildChatInput(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader(Offset currentPos, double maxDx, double maxDy) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          position = Offset(
            (position.dx + details.delta.dx).clamp(0.0, maxDx.clamp(0.0, double.infinity)),
            (position.dy + details.delta.dy).clamp(0.0, maxDy.clamp(0.0, double.infinity)),
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('FocusFlow AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            // ONLY minimize button — no close button!
            IconButton(
              icon: const Icon(Icons.minimize_rounded, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  isExpanded = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: isDark ? Colors.white60 : Colors.blueAccent),
            onPressed: isTyping ? null : _pickAndProcessAttachment,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.send_rounded, color: isTyping ? Colors.grey : const Color(0xFF6366F1)),
            onPressed: isTyping ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
