import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';

class DownloadState {
  final int receivedBytes;
  final int totalBytes;
  DownloadState(this.receivedBytes, this.totalBytes);
  double get progress => totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
}

class ModelManagerService {
  // Singleton pattern for global state access
  static final ModelManagerService _instance = ModelManagerService._internal();
  factory ModelManagerService() => _instance;
  ModelManagerService._internal();

  final ValueNotifier<DownloadState?> downloadProgressNotifier = ValueNotifier(null);
  static const String _modelFileName = 'gemma-2-2b-it-q4_k_m.gguf';
  
  // Direct HuggingFace download link for Gemma 2 2B Instruct (Q4 quantized for mobile)
  static const String _modelDownloadUrl = 'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf';

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
      final dir = await getApplicationDocumentsDirectory();
      downloadProgressNotifier.value = DownloadState(0, 2000 * 1024 * 1024); // Estimate 2GB initially
      
      final task = DownloadTask(
        url: _modelDownloadUrl,
        filename: _modelFileName,
        directory: dir.path,
        updates: Updates.statusAndProgress,
        retries: 3,
        allowPause: true,
      );

      FileDownloader().configureNotificationForGroup(
        FileDownloader.defaultGroup,
        running: const TaskNotification('Downloading Gemma 4 Model', 'file: {filename} - {progress}'),
        complete: const TaskNotification('Model Downloaded', 'The AI model is ready.'),
        error: const TaskNotification('Download Failed', 'Could not download the model.'),
        progressBar: true,
      );

      final result = await FileDownloader().download(
        task,
        onProgress: (progress) {
          // Progress is 0.0 to 1.0. The exact MBs aren't provided by FileDownloader's generic callback, 
          // so we calculate mock bytes based on the known 2GB size, or better, we can use the exact task expected file size if available.
          // FileDownloader gives us raw progress (double).
          // We know the file is ~2.0 GB.
          int totalBytes = 2147483648; // 2 GB
          int receivedBytes = (progress * totalBytes).round();
          downloadProgressNotifier.value = DownloadState(receivedBytes, totalBytes);
          onReceiveProgress(receivedBytes, totalBytes);
        },
      );

      downloadProgressNotifier.value = null;
      if (result.status == TaskStatus.complete) {
        onSuccess('${dir.path}/$_modelFileName');
      } else {
        onError('Download status: ${result.status.name}');
      }
    } catch (e) {
      downloadProgressNotifier.value = null;
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
