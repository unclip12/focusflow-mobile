import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Open all Hive boxes used across the app
  await Future.wait([
    Hive.openBox('todays_plan'),
    Hive.openBox('knowledge_base'),
    Hive.openBox('fa_logger'),
    Hive.openBox('focus_timer'),
    Hive.openBox('time_logger'),
    Hive.openBox('fmge'),
    Hive.openBox('revision'),
    Hive.openBox('analytics'),
    Hive.openBox('backups'),
    Hive.openBox('settings'),
  ]);

  runApp(const ProviderScope(child: FocusFlowApp()));
}
