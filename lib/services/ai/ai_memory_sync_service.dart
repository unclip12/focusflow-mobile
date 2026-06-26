import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/activity_log.dart';
import 'package:focusflow_mobile/services/ai/rag_database_service.dart';
import 'package:focusflow_mobile/services/database_service.dart';

class AiMemorySyncService {
  static final AiMemorySyncService _instance = AiMemorySyncService._internal();
  factory AiMemorySyncService() => _instance;
  AiMemorySyncService._internal();

  final _rag = RagDatabaseService();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _rag.init();
    _initialized = true;
  }

  void syncTimelineBlock(String date, Block block) {
    if (!_initialized) init();

    final statusStr = block.status.name.toUpperCase();
    final timeStr = '${block.plannedStartTime} - ${block.plannedEndTime}';
    final text = 'On $date, the user had a timeline block "$timeStr" for "${block.title}". Status: $statusStr. Duration: ${block.plannedDurationMinutes} mins.';
    
    // Fire and forget vectorization
    unawaited(_rag.indexDocument(text, 'block_${date}_${block.id}', 'timeline_block'));
  }

  void syncActivityLog(ActivityLogEntry entry) {
    if (!_initialized) init();

    final dateStr = entry.timestamp.length >= 10 ? entry.timestamp.substring(0, 10) : entry.timestamp;
    final text = 'On $dateStr, the user performed action "${entry.action}" on item "${entry.title}" (${entry.itemType}). Details: ${entry.details}';
    
    // Fire and forget vectorization
    unawaited(_rag.indexDocument(text, 'activity_${entry.itemType}_${entry.itemId}_${entry.timestamp}', 'activity_log'));
  }

  // Historical sync for the AI Memory Vault
  Future<void> syncHistoricalData(void Function(String status, double progress) onProgress) async {
    if (!_initialized) await init();
    
    final db = DatabaseService.instance;
    final activityLogs = await db.getAllActivityLogs();
    final dayPlans = await db.getAllDayPlans();
    
    int total = activityLogs.length + dayPlans.length;
    if (total == 0) {
      onProgress('No historical data found.', 1.0);
      return;
    }

    int current = 0;
    final batchDocs = <Map<String, String>>[];

    // Process Day Plans (Timeline Blocks)
    for (final dp in dayPlans) {
      final date = dp['date'] as String;
      if (dp['data'] != null) {
        try {
          final List<dynamic> rawBlocks = jsonDecode(dp['data'] as String);
          final blocks = rawBlocks.map((e) => Block.fromJson(e as Map<String, dynamic>)).toList();
          for (final block in blocks) {
            final statusStr = block.status.name.toUpperCase();
            final timeStr = '${block.plannedStartTime} - ${block.plannedEndTime}';
            final text = 'On $date, the user had a timeline block "$timeStr" for "${block.title}". Status: $statusStr. Duration: ${block.plannedDurationMinutes} mins.';
            batchDocs.add({
              'text': text,
              'sourceId': 'block_${date}_${block.id}',
              'sourceType': 'timeline_block',
            });
          }
        } catch (e) {
          debugPrint('Error parsing historical day plan: $e');
        }
      }
      current++;
      onProgress('Processing timeline blocks...', current / total);
      // Yield to event loop
      await Future.delayed(const Duration(milliseconds: 2));
    }

    // Process Activity Logs
    for (final entry in activityLogs) {
      final dateStr = entry.timestamp.length >= 10 ? entry.timestamp.substring(0, 10) : entry.timestamp;
      final text = 'On $dateStr, the user performed action "${entry.action}" on item "${entry.title}" (${entry.itemType}). Details: ${entry.details}';
      batchDocs.add({
        'text': text,
        'sourceId': 'activity_${entry.itemType}_${entry.itemId}_${entry.timestamp}',
        'sourceType': 'activity_log',
      });
      current++;
      onProgress('Processing activity logs...', current / total);
      await Future.delayed(const Duration(milliseconds: 2));
    }

    onProgress('Saving to vector database...', 0.95);
    await _rag.batchIndexDocuments(batchDocs);
    onProgress('Sync complete!', 1.0);
  }
}
