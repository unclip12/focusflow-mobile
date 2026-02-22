import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class KBEntry {
  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final DateTime createdAt;

  KBEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'title': title, 'content': content,
        'category': category, 'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  factory KBEntry.fromMap(Map m) => KBEntry(
        id: m['id'], title: m['title'], content: m['content'],
        category: m['category'] ?? 'General',
        tags: List<String>.from(m['tags'] ?? []),
        createdAt: DateTime.parse(m['createdAt']),
      );
}

final kbProvider =
    StateNotifierProvider<KBNotifier, List<KBEntry>>((ref) => KBNotifier());

final kbSearchProvider  = StateProvider<String>((ref) => '');
final kbCategoryProvider = StateProvider<String>((ref) => 'All');

final filteredKBProvider = Provider<List<KBEntry>>((ref) {
  final entries  = ref.watch(kbProvider);
  final search   = ref.watch(kbSearchProvider).toLowerCase();
  final category = ref.watch(kbCategoryProvider);
  return entries.where((e) {
    final matchCat  = category == 'All' || e.category == category;
    final matchSearch = search.isEmpty ||
        e.title.toLowerCase().contains(search) ||
        e.content.toLowerCase().contains(search) ||
        e.tags.any((t) => t.toLowerCase().contains(search));
    return matchCat && matchSearch;
  }).toList();
});

class KBNotifier extends StateNotifier<List<KBEntry>> {
  KBNotifier() : super([]) { _load(); }

  Box get _box => Hive.box('knowledge_base');
  final _uuid = const Uuid();

  void _load() {
    final raw = _box.get('entries');
    if (raw != null) {
      state = (raw as List)
          .map((e) => KBEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  void _save() => _box.put('entries', state.map((e) => e.toMap()).toList());

  void add(String title, String content, String category, List<String> tags) {
    state = [
      KBEntry(
        id: _uuid.v4(), title: title, content: content,
        category: category, tags: tags, createdAt: DateTime.now(),
      ),
      ...state,
    ];
    _save();
  }

  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  List<String> get allCategories {
    final cats = state.map((e) => e.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }
}
