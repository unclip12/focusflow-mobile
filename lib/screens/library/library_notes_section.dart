import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/library/add_note_sheet.dart';
import 'package:focusflow_mobile/screens/library/attachment_helper.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/show_app_bottom_sheet.dart';

class LibraryNotesSection extends StatefulWidget {
  final String itemId;
  final String itemType;
  final AppProvider app;
  final bool isDark;

  const LibraryNotesSection({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.app,
    required this.isDark,
  });

  @override
  State<LibraryNotesSection> createState() => _LibraryNotesSectionState();
}

class _LibraryNotesSectionState extends State<LibraryNotesSection> {
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

  Future<void> _renameAttachment(
    LibraryNote note,
    int attachmentIndex,
  ) async {
    if (attachmentIndex < 0 || attachmentIndex >= note.attachments.length) {
      return;
    }
    final attachment = note.attachments[attachmentIndex];
    final controller = TextEditingController(text: attachment.displayName);
    final nextName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename attachment'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Display name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (nextName == null) return;
    final trimmedName = nextName.trim();
    final updatedAttachments =
        List<LibraryNoteAttachment>.from(note.attachments);
    updatedAttachments[attachmentIndex] =
        updatedAttachments[attachmentIndex].copyWith(
      displayName: trimmedName,
    );
    await widget.app.saveLibraryNote(
      note.copyWith(attachments: updatedAttachments),
    );
    await _loadNotes();
  }

  Future<void> _deleteAttachment(
    LibraryNote note,
    int attachmentIndex,
  ) async {
    if (attachmentIndex < 0 || attachmentIndex >= note.attachments.length) {
      return;
    }

    final attachment = note.attachments[attachmentIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete attachment?'),
          content: Text(
            'Remove "${attachment.displayName}" from this note?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.danger,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }
    if (!mounted) {
      return;
    }

    final willBecomeEmpty = note.attachments.length == 1 &&
        note.noteText.trim().isEmpty &&
        note.tags.isEmpty;

    var deleteEmptyNote = false;
    if (willBecomeEmpty) {
      final shouldDeleteNote = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete empty note?'),
            content: const Text(
              'Removing this attachment will leave the note empty. Delete the note too?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep note'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.danger,
                ),
                child: const Text('Delete note'),
              ),
            ],
          );
        },
      );

      if (shouldDeleteNote == null) {
        return;
      }
      if (!shouldDeleteNote) {
        return;
      }
      if (!mounted) {
        return;
      }
      deleteEmptyNote = true;
    }

    await widget.app.removeLibraryNoteAttachment(
      note: note,
      attachmentIndex: attachmentIndex,
      deleteEmptyNote: deleteEmptyNote,
    );
    if (!mounted) {
      return;
    }
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    if (_notes == null) {
      return Center(
        child: CircularProgressIndicator(
          color: DashboardColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _notes!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : DashboardColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DashboardColors.glassBorder(isDark),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.note_alt_rounded,
                          size: 28,
                          color: DashboardColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: _inter(
                          size: 14,
                          weight: FontWeight.w500,
                          color: DashboardColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap below to add your first note',
                        style: _inter(
                          size: 12,
                          weight: FontWeight.w400,
                          color: DashboardColors.textSecondary
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  itemCount: _notes!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = _notes![index];
                    return _LibraryNoteCard(
                      note: note,
                      isDark: isDark,
                      onRenameAttachment: (attachmentIndex) =>
                          _renameAttachment(note, attachmentIndex),
                      onDeleteAttachment: (attachmentIndex) =>
                          _deleteAttachment(note, attachmentIndex),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: DashboardColors.glassBorder(isDark),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: _GlassActionButton(
                icon: Icons.add_rounded,
                label: 'Add Note / Attachment',
                color: DashboardColors.primary,
                isDark: isDark,
                onTap: () async {
                  final added = await showAppBottomSheet<bool>(
                    context: context,
                    initialChildSize: 0.7,
                    minChildSize: 0.4,
                    maxChildSize: 0.95,
                    builder: (_, scrollController) => AddNoteSheet(
                      itemId: widget.itemId,
                      itemType: widget.itemType,
                      app: widget.app,
                      scrollController: scrollController,
                    ),
                  );
                  if (added == true) {
                    await _loadNotes();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryNoteCard extends StatelessWidget {
  final LibraryNote note;
  final bool isDark;
  final ValueChanged<int> onRenameAttachment;
  final ValueChanged<int> onDeleteAttachment;

  const _LibraryNoteCard({
    required this.note,
    required this.isDark,
    required this.onRenameAttachment,
    required this.onDeleteAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DashboardColors.glassBorder(isDark),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.noteText.isNotEmpty)
            Text(
              note.noteText,
              style: _inter(
                size: 13,
                weight: FontWeight.w400,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DashboardColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              DashboardColors.primary.withValues(alpha: 0.18),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: _inter(
                          size: 10,
                          weight: FontWeight.w600,
                          color: DashboardColors.primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (note.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              children: [
                for (var index = 0;
                    index < note.attachments.length;
                    index++) ...[
                  if (index > 0) const SizedBox(height: 8),
                  _AttachmentRow(
                    attachment: note.attachments[index],
                    isDark: isDark,
                    onOpen: () => AttachmentHelper.openNoteAttachment(
                      context,
                      note.attachments[index],
                    ),
                    onRename: () => onRenameAttachment(index),
                    onDelete: () => onDeleteAttachment(index),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final LibraryNoteAttachment attachment;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _AttachmentRow({
    required this.attachment,
    required this.isDark,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DashboardColors.glassBorder(isDark),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AttachmentHelper.getAttachmentIcon(attachment),
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _inter(
                        size: 12,
                        weight: FontWeight.w600,
                        color: DashboardColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _inter(
                        size: 10,
                        weight: FontWeight.w400,
                        color: DashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRename,
                icon: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: DashboardColors.textSecondary,
                ),
                tooltip: 'Rename',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    if (attachment.kind == LibraryNoteAttachmentKind.link) {
      return attachment.source;
    }
    if (attachment.displayName !=
        LibraryNoteAttachment.deriveDisplayName(
          attachment.source,
        )) {
      return LibraryNoteAttachment.deriveDisplayName(attachment.source);
    }
    switch (attachment.kind) {
      case LibraryNoteAttachmentKind.image:
        return 'Image attachment';
      case LibraryNoteAttachmentKind.pdf:
        return 'PDF attachment';
      case LibraryNoteAttachmentKind.video:
        return 'Video attachment';
      case LibraryNoteAttachmentKind.audio:
        return 'Audio attachment';
      default:
        return 'Attachment';
    }
  }

  Color _iconColor() {
    switch (attachment.kind) {
      case LibraryNoteAttachmentKind.link:
        return DashboardColors.primary;
      case LibraryNoteAttachmentKind.pdf:
        return DashboardColors.danger;
      case LibraryNoteAttachmentKind.video:
        return DashboardColors.warning;
      case LibraryNoteAttachmentKind.audio:
        return DashboardColors.success;
      case LibraryNoteAttachmentKind.image:
        return DashboardColors.primaryViolet;
      default:
        return DashboardColors.textSecondary;
    }
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: _inter(
                size: 13,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _inter({
  required double size,
  required FontWeight weight,
  required Color color,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}
