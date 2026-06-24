import 'package:focusflow_mobile/services/offline_suggestion_catalog.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/emoji_helper.dart';

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

    // 1. Try our massive dictionary first for custom emoji!
    final customEmoji = EmojiHelper.getEmojiForTask(input);
    if (customEmoji != null) {
      final category = _resolveCategoryFromEmoji(customEmoji);
      final colorHex = _resolveColorFromCategory(category);
      return TaskSuggestion(
        emoji: customEmoji,
        category: category,
        colorHex: colorHex,
      );
    }

    // 2. Fall back to offline catalog
    final suggestion = OfflineSuggestionCatalog.suggest(input);
    return TaskSuggestion(
      emoji: suggestion.emoji,
      category: suggestion.category,
      colorHex: suggestion.colorHex,
    );
  }

  static BlockType _resolveCategoryFromEmoji(String emoji) {
    switch (emoji) {
      case '📚':
      case '📖':
      case '🎓':
        return BlockType.revisionFa;
      case '🎬':
      case '📺':
      case '🎞️':
        return BlockType.video;
      case '📝':
      case '✍️':
      case '📂':
        return BlockType.qbank;
      case '🧠':
      case '💡':
        return BlockType.anki;
      case '☕':
      case '🍳':
      case '🍽️':
      case '🍛':
      case '🍎':
      case '🍕':
      case '🍔':
      case '🥗':
      case '🍗':
      case '🍲':
      case '🍰':
      case '🍺':
      case '🥤':
        return BlockType.breakBlock;
      default:
        return BlockType.other;
    }
  }

  static String _resolveColorFromCategory(BlockType category) {
    switch (category) {
      case BlockType.revisionFa:
      case BlockType.studySession:
      case BlockType.fmgeRevision:
        return '#3B82F6'; // Study - Blue
      case BlockType.video:
        return '#8B5CF6'; // Video - Purple
      case BlockType.qbank:
        return '#10B981'; // Qbank - Green
      case BlockType.anki:
        return '#F59E0B'; // Anki - Orange
      case BlockType.breakBlock:
        return '#EF4444'; // Break - Red
      case BlockType.mixed:
        return '#EC4899'; // Mixed - Pink
      case BlockType.other:
        return '#E8837A'; // Other - Coral
    }
  }
}
