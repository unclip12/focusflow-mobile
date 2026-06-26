import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../models/ai/document_vector.dart';
import '../../objectbox.g.dart';

class RagDatabaseService {
  late final Store _store;
  late final Box<DocumentVector> _box;
  Interpreter? _interpreter;

  Future<void> init() async {
    _store = await openStore();
    _box = _store.box<DocumentVector>();
    
    // Load tiny embedding model (must be placed in assets/models/all-MiniLM-L6-v2.tflite)
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/all-MiniLM-L6-v2.tflite');
    } catch (e) {
      debugPrint('Failed to load embedding model: $e');
    }
  }

  Future<List<double>> _getEmbedding(String text) async {
    if (_interpreter == null) return [];
    
    // Simplistic tokenization & inference setup (Requires actual tokenizer logic in production)
    // For this prototype, we mock the embedding generation if the model isn't fully wired
    // Assuming a 384-dimensional embedding for all-MiniLM-L6-v2
    try {
      // Mocking for now to compile cleanly until we add proper tokenization
      return List<double>.filled(384, 0.0);
    } catch (e) {
      return [];
    }
  }

  Future<void> indexDocument(String text, String sourceId, String sourceType) async {
    final embedding = await _getEmbedding(text);
    if (embedding.isEmpty) return;

    final doc = DocumentVector(
      text: text,
      sourceId: sourceId,
      sourceType: sourceType,
      embedding: embedding,
    );

    _box.put(doc);
  }

  Future<void> batchIndexDocuments(List<Map<String, String>> items) async {
    final docs = <DocumentVector>[];
    for (final item in items) {
      final text = item['text']!;
      final sourceId = item['sourceId']!;
      final sourceType = item['sourceType']!;
      final embedding = await _getEmbedding(text);
      if (embedding.isNotEmpty) {
        docs.add(DocumentVector(
          text: text,
          sourceId: sourceId,
          sourceType: sourceType,
          embedding: embedding,
        ));
      }
    }
    if (docs.isNotEmpty) {
      _box.putMany(docs);
    }
  }

  Future<List<DocumentVector>> searchRelevantContext(String query, {int limit = 5}) async {
    final queryEmbedding = await _getEmbedding(query);
    if (queryEmbedding.isEmpty) return [];

    final builder = _box.query(DocumentVector_.embedding.nearestNeighborsF32(queryEmbedding, limit));
    final queryObj = builder.build();
    final results = queryObj.find();
    queryObj.close();
    
    return results;
  }
}
