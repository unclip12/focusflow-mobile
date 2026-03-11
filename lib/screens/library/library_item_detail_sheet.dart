import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/library/add_note_sheet.dart';
import 'package:focusflow_mobile/screens/library/edit_metadata_sheet.dart';

class LibraryItemDetailSheet extends StatefulWidget {
  final AppProvider app;
  final dynamic item; // SketchyVideo or PathomaChapter
  final String itemType; // 'sketchy' or 'pathoma'

  const LibraryItemDetailSheet({
    super.key,
    required this.app,
    required this.item,
    required this.itemType,
  });

  @override
  State<LibraryItemDetailSheet> createState() => _LibraryItemDetailSheetState();
}

class _LibraryItemDetailSheetState extends State<LibraryItemDetailSheet>
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

  dynamic get _item {
    if (widget.itemType == 'sketchy') {
      final sketchy = widget.item as SketchyVideo;
      return widget.app.sketchyMicroVideos.firstWhere(
        (v) => v.id == sketchy.id,
        orElse: () => widget.app.sketchyPharmVideos.firstWhere(
          (v) => v.id == sketchy.id,
          orElse: () => widget.item,
        ),
      );
    } else {
      final pathoma = widget.item as PathomaChapter;
      return widget.app.pathomaChapters.firstWhere(
        (c) => c.id == pathoma.id,
        orElse: () => widget.item,
      );
    }
  }

  String get _itemId {
    if (widget.itemType == 'sketchy') {
      return 'sketchy:${(widget.item as SketchyVideo).id}';
    } else {
      return 'pathoma:${(widget.item as PathomaChapter).id}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dynamic item = _item;

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
                          item.customTitle ?? item.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        if (item.customTitle != null)
                          Text(
                            'Original: ${item.title}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          widget.itemType == 'sketchy'
                              ? '${item.category} • ${item.subcategory}'
                              : 'Chapter ${item.chapter}',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.userDescription?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.userDescription!,
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
                          initialTitle: item.customTitle,
                          initialDescription: item.userDescription,
                          onSave: (title, desc) {
                            final updated = item.copyWith(
                              customTitle: title,
                              userDescription: desc,
                            );
                            if (widget.itemType == 'sketchy') {
                              widget.app.updateSketchyMetadata(updated);
                            } else {
                              widget.app.updatePathomaMetadata(updated);
                            }
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
                Tab(text: 'Progress'),
                Tab(text: 'Notes & Attachments'),
              ],
              labelColor: cs.primary,
              indicatorColor: cs.primary,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProgressTab(
                    item: item,
                    itemType: widget.itemType,
                    app: widget.app,
                    scrollController: scrollController,
                  ),
                  _NotesTab(
                    itemId: _itemId,
                    itemType: widget.itemType,
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

class _ProgressTab extends StatelessWidget {
  final dynamic item;
  final String itemType;
  final AppProvider app;
  final ScrollController scrollController;

  const _ProgressTab({
    required this.item,
    required this.itemType,
    required this.app,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        SwitchListTile(
          value: item.watched,
          onChanged: (val) {
            if (itemType == 'sketchy') {
              if (item.category.toString().toLowerCase().contains('micro')) {
                app.toggleSketchyMicroWatched(item.id, val);
              } else {
                app.toggleSketchyPharmWatched(item.id, val);
              }
            } else {
              app.togglePathomaChapterWatched(item.id, val);
            }
          },
          title: const Text('Mark as Watched'),
          subtitle: Text(
            item.watched ? 'You have watched this.' : 'You have not watched this yet.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          activeTrackColor: cs.primary,
        ),
      ],
    );
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
                          size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final note = _notes![i];
                    return Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
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
                                          labelStyle: const TextStyle(fontSize: 11),
                                          backgroundColor: cs.secondaryContainer,
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
                                    avatar: const Icon(Icons.attachment_rounded, size: 14),
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
            border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
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
