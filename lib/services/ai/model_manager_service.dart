import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ModelManagerService {
  static const String _modelFileName = 'gemma-2b-it-q4_k_m.gguf';
  
  // Replace with actual GGUF direct download link when ready
  static const String _modelDownloadUrl = 'https://huggingface.co/google/gemma-2b-it-GGUF/resolve/main/2b-it-v1.1/gemma-2b-it-v1.1-q4_k_m.gguf';

  final Dio _dio = Dio();

  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_modelFileName';
  }

  Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    final file = File(path);
    return await file.exists() && await file.length() > 0;
  }

  Future<void> downloadModel({
    required Function(int received, int total) onReceiveProgress,
    required Function(String path) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final path = await getModelPath();
      await _dio.download(
        _modelDownloadUrl,
        path,
        onReceiveProgress: onReceiveProgress,
      );
      onSuccess(path);
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> deleteModel() async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
