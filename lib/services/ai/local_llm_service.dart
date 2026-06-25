import 'dart:async';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LocalLlmService {
  static final LocalLlmService _instance = LocalLlmService._internal();
  factory LocalLlmService() => _instance;
  LocalLlmService._internal();

  Llama? _llama;
  bool _isReady = false;
  String _systemContext = '';

  final StreamController<Map<String, String>> chatStream = StreamController<Map<String, String>>.broadcast();

  bool get isReady => _isReady;

  Future<void> init(String modelPath) async {
    if (_isReady) return;
    _llama = Llama(modelPath);
    _isReady = true;
  }

  Future<void> syncDataToAI() async {
    // Read user data from ObjectBox / DatabaseService
    // We will simulate reading day plans to construct a schedule context
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real implementation, we would query DatabaseService.instance.getUpcomingTasks() etc.
    _systemContext = "The user has 3 upcoming study blocks for USMLE Step 1. They are behind on Pathology.";
    
    // Notify chat widget
    chatStream.add({'role': 'ai', 'content': "I'm done analyzing all of your data! I noticed you have some USMLE tasks coming up. How about you study Pathology next?"});
  }

  Future<String> generateResponse(String prompt) async {
    if (!_isReady || _llama == null) {
      throw Exception('LLM not initialized. Download model first.');
    }
    
    // For demonstration of native functionality:
    // This is synchronous in llama_cpp_dart usually, but wrapped in compute or Future
    await Future.delayed(const Duration(seconds: 1));
    return 'This is a locally generated response using context [$_systemContext]. You said: $prompt';
  }

  void dispose() {
    _llama?.dispose();
    chatStream.close();
  }
}
