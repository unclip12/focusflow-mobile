import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/services/seed_service.dart';
import 'package:focusflow_mobile/services/uworld_seed.dart';
import 'package:focusflow_mobile/services/sketchy_micro_seed.dart';
import 'package:focusflow_mobile/services/sketchy_pharm_seed.dart';
import 'package:focusflow_mobile/services/pathoma_seed.dart';

/// SplashScreen — shown on every launch.
/// Performs ALL heavy init (DB open, FA seed, Sketchy, Pathoma, UWorld)
/// in the background while showing logo + status text.
/// Navigates to /dashboard when done.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _status = 'Starting up…';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    // Run seeding after first frame so UI is visible first
    WidgetsBinding.instance.addPostFrameCallback((_) => _runInit());
  }

  Future<void> _runInit() async {
    try {
      // 1. Open SQLite (creates tables if needed)
      _setStatus('Initialising database…');
      await DatabaseService.instance.database;

      // 2. Seed FA 2025 pages (skips if already seeded)
      _setStatus('Loading First Aid 2025…');
      await SeedService.seedIfNeeded();

      // 3. Seed Sketchy Micro (skips if already seeded)
      _setStatus('Loading Sketchy Micro…');
      await DatabaseService.instance.seedSketchyMicro(sketchyMicroSeed);

      // 4. Seed Sketchy Pharm (skips if already seeded)
      _setStatus('Loading Sketchy Pharm…');
      await DatabaseService.instance.seedSketchyPharm(sketchyPharmSeed);

      // 5. Seed Pathoma (skips if already seeded)
      _setStatus('Loading Pathoma…');
      await DatabaseService.instance.seedPathoma(pathomaSeed);

      // 6. Seed UWorld topics (skips if already seeded)
      _setStatus('Loading UWorld…');
      await DatabaseService.instance.seedUWorld(uworldSeed);

      // 7. Reload all provider data so the app state is fully populated
      _setStatus('Preparing app…');
      if (mounted) {
        final app = context.read<AppProvider>();
        await app.loadAll();
      }

      // Done — navigate to dashboard or last active tab
      _setStatus('Ready!');
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final lastTab = prefs.getString('lastActiveTab') ?? 'dashboard';
        if (!mounted) return;
        context.go('/$lastTab');
      }
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _status = msg);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon / logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 56,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'FocusFlow',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Study smarter. Score higher.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  color: theme.colorScheme.primary,
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
