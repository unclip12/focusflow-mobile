import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('todays_plan');
  await Hive.openBox('knowledge_base');
  await Hive.openBox('fa_logger');
  await Hive.openBox('focus_timer');
  await Hive.openBox('time_logger');
  await Hive.openBox('fmge');
  await Hive.openBox('revision');
  await Hive.openBox('analytics');
  await Hive.openBox('backups');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: FocusFlowApp()));
}
