// =============================================================
// FMGEScreen — shows FMGE entries with 3 tabs: DUE, ALL, MASTERED
// Uses AppScaffold. Entries shown as FMGEEntryCard.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/fmge_entry.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/fmge/fmge_entry_card.dart';
import 'package:focusflow_mobile/screens/fmge/fmge_entry_detail_screen.dart';

class FMGEScreen extends StatefulWidget {
  const FMGEScreen({super.key});

  @override
  State<FMGEScreen> createState() => _FMGEScreenState();
}

class _FMGEScreenState extends State<FMGEScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const String mode = 'balanced';

    final all = app.fmgeEntries;
    final due = all
        .where((e) => SrsService.isDueNow(nextRevisionAt: e.nextRevisionAt))
        .toList();
    final mastered = all
        .where((e) => SrsService.isMastered(
            revisionIndex: e.currentRevisionIndex, mode: mode))
        .toList();

    return AppScaffold(
      screenName: 'FMGE Prep',
      body: Column(
        children: [
          // ── Tab bar ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurface.withValues(alpha: 0.45),
              labelStyle: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: 'Due (${due.length})'),
                Tab(text: 'All (${all.length})'),
                Tab(text: 'Mastered (${mastered.length})'),
              ],
            ),
          ),

          // ── Tab views ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _EntryList(entries: due, emptyLabel: 'No entries due right now'),
                _EntryList(entries: all, emptyLabel: 'No FMGE entries yet'),
                _EntryList(
                    entries: mastered,
                    emptyLabel: 'No mastered entries yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Entry list widget ───────────────────────────────────────────
class _EntryList extends StatelessWidget {
  final List<FMGEEntry> entries;
  final String emptyLabel;

  const _EntryList({required this.entries, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_services_outlined,
                size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              emptyLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return FMGEEntryCard(
          entry: entry,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FMGEEntryDetailScreen(entryId: entry.id),
              ),
            );
          },
        );
      },
    );
  }
}
