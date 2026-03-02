import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';

class AddNoteSheet extends StatefulWidget {
  final String itemId;
  final String itemType;
  final AppProvider app;

  const AddNoteSheet({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.app,
  });

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _textCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final List<String> _tags = [];
  final List<String> _attachments = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachments.add(image.path);
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachments.add(result.files.single.path!);
      });
    }
  }

  void _saveNote() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    final note = LibraryNote(
      id: const Uuid().v4(),
      itemId: widget.itemId,
      itemType: widget.itemType,
      noteText: text,
      tags: List.from(_tags),
      attachmentPaths: List.from(_attachments),
      createdAt: DateTime.now().toIso8601String(),
    );

    widget.app.saveLibraryNote(note);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          // Tags
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  decoration: InputDecoration(
                    hintText: 'Add a tag...',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          // Attachments
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachments.map((path) {
                final filename = path.split('/').last.split('\\').last;
                return Chip(
                  label: Text(filename),
                  onDeleted: () {
                    setState(() => _attachments.remove(path));
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveNote,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Note'),
            ),
          ),
        ],
      ),
    );
  }
}
