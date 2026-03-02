import 'package:flutter/material.dart';

class EditMetadataSheet extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final void Function(String? title, String? desc) onSave;

  const EditMetadataSheet({
    super.key,
    this.initialTitle,
    this.initialDescription,
    required this.onSave,
  });

  @override
  State<EditMetadataSheet> createState() => _EditMetadataSheetState();
}

class _EditMetadataSheetState extends State<EditMetadataSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _descCtrl = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final t = _titleCtrl.text.trim();
    final d = _descCtrl.text.trim();
    widget.onSave(
      t.isEmpty ? null : t,
      d.isEmpty ? null : d,
    );
    Navigator.pop(context);
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
              const Icon(Icons.edit_note_rounded, size: 28),
              const SizedBox(width: 12),
              Text(
                'Edit Details',
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
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Custom Title (optional)',
              hintText: 'e.g. My Study Notes on this topic',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description / Notes',
              hintText: 'Add a high-level description...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
