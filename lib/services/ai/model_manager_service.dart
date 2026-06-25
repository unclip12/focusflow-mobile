import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider/path_provider.dart';
import '../notification_service.dart';

class ModelManagerService {
  // Singleton pattern for global state access
  static final ModelManagerService _instance = ModelManagerService._internal();
  factory ModelManagerService() => _instance;
  ModelManagerService._internal();

  final ValueNotifier<double?> downloadProgressNotifier = ValueNotifier(null);
  static const String _modelFileName = 'gemma-2-2b-it-q4_k_m.gguf';
  
  // Direct HuggingFace download link for Gemma 2 2B Instruct (Q4 quantized for mobile)
  static const String _modelDownloadUrl = 'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf';

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
      downloadProgressNotifier.value = 0.0;
      
      await _dio.download(
        _modelDownloadUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgressNotifier.value = received / total;
            // Update notification every few megabytes to avoid spam
            if (received % (5 * 1024 * 1024) < 100 * 1024) { 
              NotificationService.instance.showDownloadProgress(received, total);
            }
          }
          onReceiveProgress(received, total);
        },
      );
      
      downloadProgressNotifier.value = null;
      await NotificationService.instance.clearDownloadProgress();
      onSuccess(path);
    } catch (e) {
      downloadProgressNotifier.value = null;
      await NotificationService.instance.clearDownloadProgress();
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
