import 'dart:convert';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LocalLlmService {
  LlamaProcessor? _llamaProcessor;
  bool _isReady = false;

  bool get isReady => _isReady;

  Future<void> init(String modelPath) async {
    _llamaProcessor = LlamaProcessor(
      path: modelPath,
    );
    _isReady = true;
  }

  Future<String> generateResponse(String prompt, {String? systemPrompt}) async {
    if (!_isReady || _llamaProcessor == null) {
      throw Exception('LLM not initialized. Download model first.');
    }

    final fullPrompt = (systemPrompt != null ? 'System: $systemPrompt\n' : '') + 'User: $prompt\nAI:';
    
    // In production, you'd use stream generation and proper chat templates (like ChatML).
    // _llamaProcessor!.prompt(fullPrompt);
    
    // We would listen to the stream, this is a mock interface for now to ensure compilation.
    await Future.delayed(const Duration(seconds: 1));
    return 'This is a mocked response. You asked: $prompt';
  }

  void dispose() {
    _llamaProcessor?.unloadModel();
  }
}
