import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class OfflineSuggestion {
  final String emoji;
  final int? defaultMinutes;
  final List<String> checklistSuggestions;
  final String animationPreset;
  final BlockType category;
  final String colorHex;

  const OfflineSuggestion({
    required this.emoji,
    required this.defaultMinutes,
    required this.checklistSuggestions,
    required this.animationPreset,
    required this.category,
    required this.colorHex,
  });
}

class OfflineSuggestionCatalog {
  static const _assetPath = 'assets/data/routine_suggestions.json';
  static const OfflineSuggestion _defaultSuggestion = OfflineSuggestion(
    emoji: '✨',
    defaultMinutes: 10,
    checklistSuggestions: <String>[],
    animationPreset: 'pulse',
    category: BlockType.other,
    colorHex: '#E8837A',
  );

  static bool _initialized = false;
  static List<_KeywordRule> _rules = const <_KeywordRule>[];

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final jsonString = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Suggestion catalog must be a JSON object.');
    }
    final rawEntries = decoded['entries'];
    if (rawEntries is! List) {
      throw const FormatException('Suggestion catalog entries must be a list.');
    }

    final rules = <_KeywordRule>[];
    for (final rawEntry in rawEntries) {
      if (rawEntry is! Map) continue;
      final entry = _CatalogEntry.fromJson(Map<String, dynamic>.from(rawEntry));
      for (final rawKeyword in entry.keywords) {
        final keyword = _normalize(rawKeyword);
        if (keyword.isEmpty) continue;
        rules.add(_KeywordRule(keyword: keyword, suggestion: entry.suggestion));
      }
    }
    rules.sort((a, b) => b.keyword.length.compareTo(a.keyword.length));
    _rules = List<_KeywordRule>.unmodifiable(rules);
    _initialized = true;
  }

  static bool get isInitialized => _initialized;

  static OfflineSuggestion suggest(String input) {
    final normalizedInput = _normalize(input);
    if (normalizedInput.isEmpty || _rules.isEmpty) {
      return _defaultSuggestion;
    }

    for (final rule in _rules) {
      if (normalizedInput.contains(rule.keyword)) {
        return rule.suggestion;
      }
    }
    return _defaultSuggestion;
  }

  static List<String> checklistSuggestionsFor(String input) {
    return suggest(input).checklistSuggestions;
  }

  static String animationPresetFor(String input) {
    return suggest(input).animationPreset;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _CatalogEntry {
  final List<String> keywords;
  final OfflineSuggestion suggestion;

  const _CatalogEntry({
    required this.keywords,
    required this.suggestion,
  });

  factory _CatalogEntry.fromJson(Map<String, dynamic> json) {
    return _CatalogEntry(
      keywords: (json['keywords'] as List? ?? const <dynamic>[])
          .map((keyword) => keyword.toString())
          .toList(growable: false),
      suggestion: OfflineSuggestion(
        emoji: json['emoji']?.toString() ?? '✨',
        defaultMinutes: json['defaultMinutes'] as int?,
        checklistSuggestions:
            (json['checklistSuggestions'] as List? ?? const <dynamic>[])
                .map((item) => item.toString())
                .toList(growable: false),
        animationPreset: json['animationPreset']?.toString() ?? 'pulse',
        category: BlockType.fromString(json['blockType']?.toString() ?? 'OTHER'),
        colorHex: json['colorHex']?.toString() ?? '#E8837A',
      ),
    );
  }
}

class _KeywordRule {
  final String keyword;
  final OfflineSuggestion suggestion;

  const _KeywordRule({
    required this.keyword,
    required this.suggestion,
  });
}
