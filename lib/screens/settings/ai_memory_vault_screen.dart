import 'package:flutter/material.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focusflow_mobile/services/ai/ai_memory_sync_service.dart';

class AiMemoryVaultScreen extends StatefulWidget {
  const AiMemoryVaultScreen({super.key});

  @override
  State<AiMemoryVaultScreen> createState() => _AiMemoryVaultScreenState();
}

class _AiMemoryVaultScreenState extends State<AiMemoryVaultScreen> {
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncStatus = 'Idle';

  Future<void> _startSync() async {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
      _syncStatus = 'Initializing...';
    });

    try {
      await AiMemorySyncService().syncHistoricalData((status, progress) {
        if (mounted) {
          setState(() {
            _syncStatus = status;
            _syncProgress = progress;
          });
        }
      });
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStatus = 'Sync Complete!';
          _syncProgress = 1.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historical data synchronized successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStatus = 'Sync Failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardColors.background(Theme.of(context).brightness == Brightness.dark),
      appBar: AppBar(
        title: Text(
          'AI Memory Vault',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: DashboardColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.memory_rounded, size: 80, color: DashboardColors.primary),
              const SizedBox(height: 24),
              Text(
                'Local AI Memory Sync',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This will process your entire timeline and activity logs, converting them into vector memories for the on-device AI to understand your context perfectly.',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isSyncing) ...[
                Text(
                  _syncStatus,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: DashboardColors.primary),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _syncProgress,
                  backgroundColor: DashboardColors.primary.withAlpha(51), // 20% opacity
                  valueColor: AlwaysStoppedAnimation<Color>(DashboardColors.primary),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_syncProgress * 100).toInt()}%',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _startSync,
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Synchronize Historical Data'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: DashboardColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
