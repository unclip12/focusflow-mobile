import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/services/offline_suggestion_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await OfflineSuggestionCatalog.ensureInitialized();
  });

  test('offline suggestion catalog returns common routine and step metadata',
      () {
    final morning = OfflineSuggestionCatalog.suggest('Morning routine');
    expect(morning.emoji, '🌅');
    expect(morning.defaultMinutes, 25);

    final bath = OfflineSuggestionCatalog.suggest('Taking bath');
    expect(bath.emoji, '🛁');
    expect(bath.defaultMinutes, 15);
    expect(bath.checklistSuggestions, containsAll(<String>[
      'Take clothes',
      'Heat water',
      'Get towel',
    ]));

    final prayer = OfflineSuggestionCatalog.suggest('Maghrib prayer');
    expect(prayer.emoji, '🕌');
    expect(prayer.animationPreset, isNotEmpty);
  });

  test('active routine run checklist state survives json roundtrip', () {
    final run = ActiveRoutineRun(
      routineId: 'routine_1',
      dateKey: '2026-04-01',
      startedAt: DateTime.parse('2026-04-01T07:00:00.000'),
      currentStepStartedAt: DateTime.parse('2026-04-01T07:05:00.000'),
      currentStepIndex: 1,
      checklistState: const <String, bool>{
        'step_1::check_1': true,
        'step_2::check_2': true,
      },
    );

    final restored = ActiveRoutineRun.fromJson(
      Map<String, dynamic>.from(jsonDecode(jsonEncode(run.toJson())) as Map),
    );

    expect(restored.checklistState, containsPair('step_1::check_1', true));
    expect(restored.isChecklistItemChecked('step_2', 'check_2'), isTrue);
  });
}
