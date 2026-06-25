import 'package:flutter/material.dart';
import '../../services/ai/local_llm_service.dart';

class PersistentAiChatWidget extends StatefulWidget {
  const PersistentAiChatWidget({super.key});

  @override
  State<PersistentAiChatWidget> createState() => _PersistentAiChatWidgetState();
}

class _PersistentAiChatWidgetState extends State<PersistentAiChatWidget> {
  static final List<Map<String, String>> _messages = [];
  static final LocalLlmService _llmService = LocalLlmService();
  bool _isVisible = true;

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
      setState(() {
        widget.messages.add({'role': 'ai', 'content': response});
        isTyping = false;
      });
    } catch (e) {
      setState(() {
        widget.messages.add({'role': 'ai', 'content': 'Error: ${e.toString()}'});
        isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: isExpanded
          ? _buildExpandedChat()
          : _buildChatHead(),
    );
  }

  Widget _buildChatHead() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          position += details.delta;
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

  Widget _buildExpandedChat() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        height: 450,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
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
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
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
            icon: const Icon(Icons.mic, color: Colors.blueAccent),
            onPressed: () {
              // TODO: Wire AssemblyAiService here
            },
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
