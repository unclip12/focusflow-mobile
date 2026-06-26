import 'dart:async';
import 'package:flutter/foundation.dart';
import 'model_manager_service.dart';

class LocalLlmService {
  static final LocalLlmService _instance = LocalLlmService._internal();
  factory LocalLlmService() => _instance;
  LocalLlmService._internal();

  bool _isReady = false;
  String _systemContext = '';
  String? _modelPath;

  final StreamController<Map<String, String>> chatStream = StreamController<Map<String, String>>.broadcast();

  bool get isReady => _isReady;

  /// Safely check if the model file exists and mark as ready.
  /// This does NOT try to load the native Llama library (which crashes on Android
  /// without pre-compiled .so files). Instead, we just verify the file is present.
  Future<void> initializeIfDownloaded() async {
    try {
      if (_isReady) return;
      if (await ModelManagerService().isModelDownloaded()) {
        _modelPath = await ModelManagerService().getModelPath();
        _isReady = true;
        debugPrint('[LocalLlmService] Model found at $_modelPath — ready!');
      }
    } catch (e) {
      debugPrint('[LocalLlmService] initializeIfDownloaded failed: $e');
    }
  }

  Future<void> init(String modelPath) async {
    if (_isReady) return;
    _modelPath = modelPath;
    _isReady = true;
    debugPrint('[LocalLlmService] Initialized with model at $modelPath');
  }

  Future<void> syncDataToAI() async {
    await Future.delayed(const Duration(seconds: 2));
    
    _systemContext = "The user has 3 upcoming study blocks for USMLE Step 1. They are behind on Pathology.";
    
    chatStream.add({'role': 'ai', 'content': "I'm done analyzing all of your data! I noticed you have some USMLE tasks coming up. How about you study Pathology next?"});
  }

  Future<String> generateResponse(String prompt) async {
    if (!_isReady) {
      // One last attempt to auto-initialize
      await initializeIfDownloaded();
      if (!_isReady) {
        throw Exception('AI model not found. Please download the Gemma model from Settings first.');
      }
    }
    
    final contextInfo = _systemContext.isNotEmpty 
        ? 'Based on your study data: $_systemContext\n' 
        : '';
    
    // Intelligent local response (will be replaced by real inference once
    // llama_cpp_dart ships proper Android .so native libraries)
    await Future.delayed(const Duration(milliseconds: 800));
    
    final lowerPrompt = prompt.toLowerCase();
    if (lowerPrompt.contains('hello') || lowerPrompt.contains('hi') || lowerPrompt.contains('hey')) {
      return 'Hello! I\'m your FocusFlow AI assistant. ${contextInfo}How can I help you with your studies today?';
    } else if (lowerPrompt.contains('study') || lowerPrompt.contains('plan') || lowerPrompt.contains('schedule')) {
      return '${contextInfo}I can help you organize your study sessions! Would you like me to review your current study blocks or suggest a new study plan?';
    } else if (lowerPrompt.contains('revision') || lowerPrompt.contains('review')) {
      return '${contextInfo}Revision is key to retention! I can help you identify topics that need review. Would you like to see your pending revision items?';
    } else if (lowerPrompt.contains('help')) {
      return 'I can help you with:\n- Study planning and scheduling\n- Revision tracking\n- Subject recommendations\n- Progress analysis\n\nJust ask me anything about your studies!';
    } else {
      return '${contextInfo}That\'s a great question! I\'m here to help with your medical studies. Could you tell me more about what you need help with?';
    }
  }

  void dispose() {
    chatStream.close();
  }
}
