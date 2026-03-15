import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/library/add_note_sheet.dart';
import 'package:focusflow_mobile/screens/library/edit_metadata_sheet.dart';

class FAPageDetailSheet extends StatefulWidget {
  final AppProvider app;
  final int pageNum;

  const FAPageDetailSheet({
    super.key,
    required this.app,
    required this.pageNum,
  });

  @override
  State<FAPageDetailSheet> createState() => _FAPageDetailSheetState();
}

class _FAPageDetailSheetState extends State<FAPageDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  FAPage get _page =>
      widget.app.faPages.firstWhere((p) => p.pageNum == widget.pageNum);

  void _cyclePageStatus(BuildContext context) {
    if (_page.status == 'anki_done') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mark as Unread?'),
          content:
              const Text('This will clear the read history for this page.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.app.updateFAPageStatus(_page.pageNum, 'unread');
              },
              child: const Text('Mark Unread'),
            ),
          ],
        ),
      );
    } else if (_page.status == 'read') {
      widget.app.updateFAPageStatus(_page.pageNum, 'anki_done');
    } else {
      widget.app.updateFAPageStatus(_page.pageNum, 'read');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final page = _page; // Get latest
    final subtopics = widget.app.getSubtopicsForPage(page.pageNum);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          page.customTitle ?? page.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        if (page.customTitle != null)
                          Text(
                            'Original: ${page.title}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Page ${page.pageNum} • ${page.subject} • ${page.system}',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (page.userDescription?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            page.userDescription!,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => EditMetadataSheet(
                          initialTitle: page.customTitle,
                          initialDescription: page.userDescription,
                          onSave: (title, desc) {
                            final updated = page.copyWith(
                              customTitle: title,
                              userDescription: desc,
                            );
                            widget.app.updateFAPageMetadata(updated);
                          },
                        ),
                      );
                    },
                    tooltip: 'Edit details',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'History & Progress'),
                Tab(text: 'Notes & Attachments'),
              ],
              labelColor: cs.primary,
              indicatorColor: cs.primary,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _HistoryTab(
                    page: page,
                    subtopics: subtopics,
                    app: widget.app,
                    scrollController: scrollController,
                    onCycleStatus: () => _cyclePageStatus(context),
                  ),
                  _NotesTab(
                    itemId: 'fa:${page.pageNum}',
                    itemType: 'fa',
                    app: widget.app,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final FAPage page;
  final List<FASubtopic> subtopics;
  final AppProvider app;
  final ScrollController scrollController;
  final VoidCallback onCycleStatus;

  const _HistoryTab({
    required this.page,
    required this.subtopics,
    required this.app,
    required this.scrollController,
    required this.onCycleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final readSubs = subtopics.where((s) => s.status != 'unread').length;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      children: [
        _detailRow('Status', page.status.toUpperCase(), cs),
        _detailRow('Subtopics', '$readSubs / ${subtopics.length} done', cs),
        if (page.firstReadAt != null)
          _detailRow('First Read', _formatDate(page.firstReadAt!), cs),
        if (page.ankiDoneAt != null)
          _detailRow('Anki Done', _formatDate(page.ankiDoneAt!), cs),
        _detailRow('Revisions', 'R${page.revisionCount}', cs),
        if (page.revisionHistory.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Revision History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...page.revisionHistory.map((r) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  'R${r.revisionNum}: ${_formatDate(r.date)}',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              )),
        ],
        const SizedBox(height: 24),
        if (page.status == 'anki_done')
          OutlinedButton(
            onPressed: onCycleStatus,
            child: const Text('Mark as Unread'),
          ),
      ],
    );
  }

  Widget _detailRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _NotesTab extends StatefulWidget {
  final String itemId;
  final String itemType;
  final AppProvider app;

  const _NotesTab({
    required this.itemId,
    required this.itemType,
    required this.app,
  });

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  List<LibraryNote>? _notes;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await widget.app.getLibraryNotes(widget.itemId);
    if (mounted) {
      setState(() => _notes = notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_notes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: _notes!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.note_alt_rounded,
                          size: 48,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  itemCount: _notes!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final note = _notes![i];
                    return Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.noteText.isNotEmpty)
                              Text(
                                note.noteText,
                                style: const TextStyle(fontSize: 14),
                              ),
                            if (note.tags.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: note.tags
                                    .map((t) => Chip(
                                          label: Text(t),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          labelStyle:
                                              const TextStyle(fontSize: 11),
                                          backgroundColor:
                                              cs.secondaryContainer,
                                          side: BorderSide.none,
                                        ))
                                    .toList(),
                              ),
                            ],
                            if (note.attachmentPaths.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: note.attachmentPaths.map((path) {
                                  return Chip(
                                    avatar: const Icon(Icons.attachment_rounded,
                                        size: 14),
                                    label: Text(path.split('/').last),
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
                top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final added = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => AddNoteSheet(
                    itemId: widget.itemId,
                    itemType: widget.itemType,
                    app: widget.app,
                  ),
                );
                if (added == true) {
                  _loadNotes();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Note / Attachment'),
            ),
          ),
        ),
      ],
    );
  }
}
