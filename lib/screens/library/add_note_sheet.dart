import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/library/attachment_helper.dart';

class AddNoteSheet extends StatefulWidget {
  final String itemId;
  final String itemType;
  final AppProvider app;
  final ScrollController? scrollController;

  const AddNoteSheet({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.app,
    this.scrollController,
  });

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _textCtrl = TextEditingController();
  final _linkNameCtrl = TextEditingController();
  final _linkUrlCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final List<String> _tags = [];
  final List<_AttachmentDraft> _attachments = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textCtrl.dispose();
    _linkNameCtrl.dispose();
    _linkUrlCtrl.dispose();
    _tagCtrl.dispose();
    for (final attachment in _attachments) {
      attachment.dispose();
    }
    super.dispose();
  }

  void _addLink() {
    final normalizedLink = AttachmentHelper.normalizeLink(_linkUrlCtrl.text);
    if (normalizedLink == null ||
        _attachments.any((attachment) => attachment.source == normalizedLink)) {
      return;
    }

    setState(() {
      _attachments.add(
        _AttachmentDraft.fromSource(
          normalizedLink,
          initialName: _linkNameCtrl.text.trim(),
        ),
      );
      _linkNameCtrl.clear();
      _linkUrlCtrl.clear();
    });
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _addAttachmentPath(image.path);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path != null) {
      _addAttachmentPath(path);
    }
  }

  void _addAttachmentPath(String path) {
    if (_attachments.any((attachment) => attachment.source == path)) {
      return;
    }
    setState(() {
      _attachments.add(_AttachmentDraft.fromSource(path));
    });
  }

  void _removeAttachment(_AttachmentDraft attachment) {
    attachment.dispose();
    setState(() {
      _attachments.remove(attachment);
    });
  }

  Future<void> _saveNote() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    final note = LibraryNote(
      id: const Uuid().v4(),
      itemId: widget.itemId,
      itemType: widget.itemType,
      noteText: text,
      tags: List<String>.from(_tags),
      attachments: _attachments
          .map((attachment) => attachment.toAttachment())
          .toList(growable: false),
      createdAt: DateTime.now().toIso8601String(),
    );

    await widget.app.saveLibraryNote(note);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 +
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.post_add_rounded, size: 28),
              const SizedBox(width: 12),
              Text(
                'Add Note / Attachment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type your note here...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add link',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _linkNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Link name',
              isDense: true,
              prefixIcon: const Icon(Icons.edit_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _linkUrlCtrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Paste website link...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.link_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _addLink(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _addLink,
                icon: const Icon(Icons.add_link_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  decoration: InputDecoration(
                    hintText: 'Add a tag...',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _addTag,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_rounded, size: 18),
                label: const Text('Image'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: const Text('File'),
              ),
            ],
          ),
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Attachments',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attachments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final attachment = _attachments[index];
                final previewAttachment = attachment.toAttachment();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                AttachmentHelper.getAttachmentIcon(
                                  previewAttachment,
                                ),
                                size: 18,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: attachment.nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Display name',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  AttachmentHelper.openNoteAttachment(
                                context,
                                previewAttachment,
                              ),
                              icon: const Icon(Icons.open_in_new_rounded),
                              tooltip: 'Preview',
                            ),
                            IconButton(
                              onPressed: () => _removeAttachment(attachment),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          attachment.source,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveNote,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Note'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentDraft {
  final String source;
  final String kind;
  final TextEditingController nameController;

  _AttachmentDraft({
    required this.source,
    required this.kind,
    required this.nameController,
  });

  factory _AttachmentDraft.fromSource(
    String source, {
    String initialName = '',
  }) {
    final fallbackName = LibraryNoteAttachment.deriveDisplayName(source);
    return _AttachmentDraft(
      source: source,
      kind: LibraryNoteAttachment.detectKind(source),
      nameController: TextEditingController(
        text: initialName.trim().isEmpty ? fallbackName : initialName.trim(),
      ),
    );
  }

  LibraryNoteAttachment toAttachment() {
    final displayName = nameController.text.trim();
    return LibraryNoteAttachment(
      source: source,
      displayName: displayName.isEmpty
          ? LibraryNoteAttachment.deriveDisplayName(source)
          : displayName,
      kind: kind,
    );
  }

  void dispose() {
    nameController.dispose();
  }
}
