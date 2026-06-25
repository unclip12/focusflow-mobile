import 'dart:convert';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LocalLlmService {
  Llama? _llama;
  bool _isReady = false;

  bool get isReady => _isReady;

  Future<void> init(String modelPath) async {
    _llama = Llama(modelPath);
    _isReady = true;
  }

  Future<String> generateResponse(String prompt, {String? systemPrompt}) async {
    if (!_isReady || _llama == null) {
      throw Exception('LLM not initialized. Download model first.');
    }
    
    // In production, you'd use stream generation and proper chat templates (like ChatML).
    // final fullPrompt = '${systemPrompt != null ? 'System: $systemPrompt\n' : ''}User: $prompt\nAI:';
    // _llama!.prompt(fullPrompt);
    
    // We would listen to the stream, this is a mock interface for now to ensure compilation.
    await Future.delayed(const Duration(seconds: 1));
    return 'This is a mocked response. You asked: $prompt';
  }

  void dispose() {
    _llama?.dispose();
  }
}
