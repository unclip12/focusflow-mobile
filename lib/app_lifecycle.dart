import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/backup_service.dart';

/// Wrap this around FocusFlowApp to capture auto-backups on app pause.
class AppLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});
  @override
  ConsumerState<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      final svc = ref.read(backupServiceProvider);
      final autoEnabled = await svc.isAutoSyncEnabled();
      if (autoEnabled) {
        final snap = svc.createSnapshot(isAuto: true);
        ref.read(backupSnapshotsProvider.notifier).add(snap);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
