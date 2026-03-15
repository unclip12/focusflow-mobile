import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/library/add_note_sheet.dart';
import 'package:focusflow_mobile/screens/library/edit_metadata_sheet.dart';

class UWorldDetailSheet extends StatefulWidget {
  final AppProvider app;
  final UWorldTopic topic;

  const UWorldDetailSheet({
    super.key,
    required this.app,
    required this.topic,
  });

  @override
  State<UWorldDetailSheet> createState() => _UWorldDetailSheetState();
}

class _UWorldDetailSheetState extends State<UWorldDetailSheet>
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

  UWorldTopic get _topic {
    return widget.app.uworldTopics.firstWhere(
      (t) => t.id == widget.topic.id,
      orElse: () => widget.topic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topic = _topic;

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
                          topic.customTitle ?? topic.subtopic,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurface,
                          ),
                        ),
                        if (topic.customTitle != null)
                          Text(
                            'Original: ${topic.subtopic}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          topic.system,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.primary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (topic.userDescription?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            topic.userDescription!,
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
                          initialTitle: topic.customTitle,
                          initialDescription: topic.userDescription,
                          onSave: (title, desc) {
                            final updated = topic.copyWith(
                              customTitle: title,
                              userDescription: desc,
                            );
                            widget.app.updateUWorldMetadata(updated);
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
                    topic: topic,
                    app: widget.app,
                    scrollController: scrollController,
                  ),
                  _NotesTab(
                    itemId: 'uworld:${topic.id}',
                    itemType: 'uworld',
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

class _ProgressTab extends StatefulWidget {
  final UWorldTopic topic;
  final AppProvider app;
  final ScrollController scrollController;

  const _ProgressTab({
    required this.topic,
    required this.app,
    required this.scrollController,
  });

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  late int _done;
  late int _correct;

  @override
  void initState() {
    super.initState();
    _done = widget.topic.doneQuestions;
    _correct = widget.topic.correctQuestions;
  }

  @override
  void didUpdateWidget(covariant _ProgressTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic.doneQuestions != widget.topic.doneQuestions ||
        oldWidget.topic.correctQuestions != widget.topic.correctQuestions) {
      _done = widget.topic.doneQuestions;
      _correct = widget.topic.correctQuestions;
    }
  }

  void _updateDone(int delta) {
    setState(() {
      _done = (_done + delta).clamp(0, widget.topic.totalQuestions);
      _correct = _correct.clamp(0, _done);
    });
  }

  void _updateCorrect(int delta) {
    setState(() {
      _correct = (_correct + delta).clamp(0, _done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topic = widget.topic;

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      children: [
        // Row 1: Done
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Questions done:',
                style: TextStyle(fontSize: 16, color: cs.onSurface)),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _done > 0 ? () => _updateDone(-1) : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 20,
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_done',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _done < topic.totalQuestions
                      ? () => _updateDone(1)
                      : null,
                  icon: const Icon(Icons.add),
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 2: Correct
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Correct:',
                style: TextStyle(fontSize: 16, color: cs.onSurface)),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _correct > 0 ? () => _updateCorrect(-1) : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 20,
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_correct',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _correct < _done ? () => _updateCorrect(1) : null,
                  icon: const Icon(Icons.add),
                  iconSize: 20,
                ), // Icon
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              widget.app.updateUWorldProgress(topic.id!, _done, _correct);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress saved')),
              );
            },
            child: const Text('Save Progress'),
          ),
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
