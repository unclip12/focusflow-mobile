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
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _llmService.chatStream.stream.listen((msg) {
      if (mounted) {
        setState(() {
          _messages.add(msg);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return _FloatingChatWidget(
      messages: _messages,
      llmService: _llmService,
      onClose: () {
        setState(() {
          _isVisible = false;
        });
      },
    );
  }
}

class _FloatingChatWidget extends StatefulWidget {
  final List<Map<String, String>> messages;
  final LocalLlmService llmService;
  final VoidCallback onClose;

  const _FloatingChatWidget({
    required this.messages,
    required this.llmService,
    required this.onClose,
  });

  @override
  State<_FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends State<_FloatingChatWidget> {
  Offset position = const Offset(20, 100);
  bool isExpanded = false;
  final TextEditingController _controller = TextEditingController();
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    PersistentAiChatWidget.expandChatNotifier.addListener(_onExpandRequested);
  }

  @override
  void dispose() {
    PersistentAiChatWidget.expandChatNotifier.removeListener(_onExpandRequested);
    super.dispose();
  }

  void _onExpandRequested() {
    if (PersistentAiChatWidget.expandChatNotifier.value && !isExpanded && mounted) {
      setState(() {
        isExpanded = true;
      });
      // Optionally reset the notifier if it's meant to be a one-time trigger
      PersistentAiChatWidget.expandChatNotifier.value = false;
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final text = _controller.text;
    _controller.clear();
    
    setState(() {
      widget.messages.add({'role': 'user', 'content': text});
      isTyping = true;
    });

    try {
      final response = await widget.llmService.generateResponse(text);
      if (mounted) {
        setState(() {
          widget.messages.add({'role': 'ai', 'content': response});
          isTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          widget.messages.add({'role': 'ai', 'content': 'Error: ${e.toString()}'});
          isTyping = false;
        });
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
    final maxDx = size.width - (isExpanded ? 320 : 60);
    final maxDy = size.height - (isExpanded ? 450 : 60);
    
    // Constrain position within bounds
    final clampedPosition = Offset(
      position.dx.clamp(0.0, maxDx),
      position.dy.clamp(0.0, maxDy),
    );
    
    return Positioned(
      left: clampedPosition.dx,
      top: clampedPosition.dy,
      child: isExpanded
          ? _buildExpandedChat(clampedPosition, maxDx, maxDy)
          : _buildChatHead(clampedPosition, maxDx, maxDy),
    );
  }

  Widget _buildChatHead(Offset currentPos, double maxDx, double maxDy) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          position = Offset(
            (currentPos.dx + details.delta.dx).clamp(0.0, maxDx),
            (currentPos.dy + details.delta.dy).clamp(0.0, maxDy),
          );
        });
      },
      onTap: () {
        setState(() {
          isExpanded = true;
        });
      },
      child: const CircleAvatar(
        radius: 30,
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.smart_toy, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildExpandedChat(Offset currentPos, double maxDx, double maxDy) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: LiquidGlassCard(
        child: SizedBox(
          width: 320,
          height: 450,
          child: Column(
          children: [
            _buildChatHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: widget.messages.length,
                itemBuilder: (context, index) {
                  final msg = widget.messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blueAccent : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['content'] ?? '',
                        style: TextStyle(color: isUser ? Colors.white : Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isTyping)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Thinking...", style: TextStyle(fontStyle: FontStyle.italic)),
                ),
              ),
            _buildChatInput(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          position += details.delta;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('FocusFlow AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.minimize, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      isExpanded = false;
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.blueAccent),
            onPressed: isTyping ? null : _pickAndProcessAttachment,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: isTyping ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
