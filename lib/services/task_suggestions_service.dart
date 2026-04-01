import 'package:focusflow_mobile/services/offline_suggestion_catalog.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class TaskSuggestion {
  final String emoji;
  final BlockType category;
  final String colorHex;

  const TaskSuggestion({
    required this.emoji,
    required this.category,
    required this.colorHex,
  });
}

class TaskSuggestionsService {
  static const TaskSuggestion _defaultSuggestion = TaskSuggestion(
    emoji: '\u{2728}',
    category: BlockType.other,
    colorHex: '#E8837A',
  );

  static TaskSuggestion suggest(String input) {
    if (input.trim().isEmpty) {
      return _defaultSuggestion;
    }

    final suggestion = OfflineSuggestionCatalog.suggest(input);
    return TaskSuggestion(
      emoji: suggestion.emoji,
      category: suggestion.category,
      colorHex: suggestion.colorHex,
    );
  }
}
