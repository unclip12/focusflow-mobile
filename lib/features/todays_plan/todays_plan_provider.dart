import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final bool isDone;
  final String category;
  final int priority; // 0=low 1=med 2=high

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    this.category = 'General',
    this.priority = 1,
  });

  Task copyWith({String? title, bool? isDone, String? category, int? priority}) => Task(
        id: id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        category: category ?? this.category,
        priority: priority ?? this.priority,
      );

  Map<String, dynamic> toMap() => {
        'id': id, 'title': title, 'isDone': isDone,
        'category': category, 'priority': priority,
      };

  factory Task.fromMap(Map m) => Task(
        id: m['id'], title: m['title'],
        isDone: m['isDone'] ?? false,
        category: m['category'] ?? 'General',
        priority: m['priority'] ?? 1,
      );
}

final todayTasksProvider =
    StateNotifierProvider<TodayTasksNotifier, List<Task>>((ref) => TodayTasksNotifier());

class TodayTasksNotifier extends StateNotifier<List<Task>> {
  TodayTasksNotifier() : super([]) { _load(); }

  Box get _box => Hive.box('todays_plan');
  final _uuid = const Uuid();

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  void _load() {
    final raw = _box.get(_todayKey);
    if (raw != null) {
      state = (raw as List)
          .map((e) => Task.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  void _save() => _box.put(_todayKey, state.map((t) => t.toMap()).toList());

  void add(String title, String category, int priority) {
    state = [...state, Task(id: _uuid.v4(), title: title, category: category, priority: priority)];
    _save();
  }

  void toggle(String id) {
    state = state.map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t).toList();
    _save();
  }

  void delete(String id) {
    state = state.where((t) => t.id != id).toList();
    _save();
  }

  int get doneCount => state.where((t) => t.isDone).length;
}
