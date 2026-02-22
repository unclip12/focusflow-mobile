import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

const faSubjects = [
  'Biochemistry',   'Physiology',     'Anatomy',
  'Pharmacology',   'Pathology',      'Microbiology',
  'Immunology',     'Cardiology',     'Pulmonology',
  'Gastroenterology', 'Neurology',    'Psychiatry',
  'Endocrinology',  'Hematology',     'Nephrology',
  'Musculoskeletal','Dermatology',    'Reproductive',
  'Embryology',
];

class FASession {
  final String id;
  final String subject;
  final int pages;
  final int durationMin;
  final String? notes;
  final DateTime date;

  FASession({
    required this.id, required this.subject,
    required this.pages, required this.durationMin,
    this.notes, required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'subject': subject, 'pages': pages,
        'durationMin': durationMin, 'notes': notes,
        'date': date.toIso8601String(),
      };

  factory FASession.fromMap(Map m) => FASession(
        id: m['id'], subject: m['subject'],
        pages: m['pages'], durationMin: m['durationMin'],
        notes: m['notes'], date: DateTime.parse(m['date']),
      );
}

final faSessionsProvider =
    StateNotifierProvider<FASessionsNotifier, List<FASession>>(
        (ref) => FASessionsNotifier());

class FASessionsNotifier extends StateNotifier<List<FASession>> {
  FASessionsNotifier() : super([]) { _load(); }

  Box get _box => Hive.box('fa_logger');
  final _uuid = const Uuid();

  void _load() {
    final raw = _box.get('sessions');
    if (raw != null) {
      state = (raw as List)
          .map((e) => FASession.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  void _save() => _box.put('sessions', state.map((e) => e.toMap()).toList());

  void addSession(String subject, int pages, int durationMin, String? notes) {
    state = [
      FASession(
        id: _uuid.v4(), subject: subject, pages: pages,
        durationMin: durationMin, notes: notes, date: DateTime.now(),
      ),
      ...state,
    ];
    _save();
  }

  void delete(String id) {
    state = state.where((s) => s.id != id).toList();
    _save();
  }

  Map<String, int> get pagesBySubject {
    final map = <String, int>{};
    for (final s in state) {
      map[s.subject] = (map[s.subject] ?? 0) + s.pages;
    }
    return map;
  }

  int totalPages() => state.fold(0, (sum, s) => sum + s.pages);
  int totalMinutes() => state.fold(0, (sum, s) => sum + s.durationMin);
}
