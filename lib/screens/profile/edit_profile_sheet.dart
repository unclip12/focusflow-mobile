// =============================================================
// EditProfileSheet — bottom sheet for editing user profile.
// Fields: display name, email (local pref only), daily study
// target hours (slider 1–12), daily blocks target (counter 1–10).
// Save calls AppProvider.saveUserProfile().
// Android rules: enableDrag: false, useSafeArea: true (set by caller).
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/user_profile.dart';

class EditProfileSheet extends StatefulWidget {
  final UserProfile? profile;
  final String? currentEmail;
  final double currentTargetHours;
  final int currentTargetBlocks;

  const EditProfileSheet({
    super.key,
    this.profile,
    this.currentEmail,
    required this.currentTargetHours,
    required this.currentTargetBlocks,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late double _targetHours;
  late int _targetBlocks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.profile?.displayName ?? '');
    _emailCtrl =
        TextEditingController(text: widget.currentEmail ?? '');
    _targetHours = widget.currentTargetHours;
    _targetBlocks = widget.currentTargetBlocks;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final ap = context.read<AppProvider>();
    final updated = UserProfile(
      displayName: name,
      searchHistory: widget.profile?.searchHistory,
    );
    await ap.saveUserProfile(updated);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ─────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Edit Profile',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_saving)
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    TextButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Form content ────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display name
                    _fieldLabel('Display Name', theme, cs),
                    const SizedBox(height: 6),
                    _TextField(
                      controller: _nameCtrl,
                      hint: 'Your name',
                      icon: Icons.person_rounded,
                      cs: cs,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _fieldLabel('Email', theme, cs),
                    const SizedBox(height: 6),
                    _TextField(
                      controller: _emailCtrl,
                      hint: 'your@email.com',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      cs: cs,
                      theme: theme,
                    ),
                    const SizedBox(height: 20),

                    // Study hours target slider
                    Row(
                      children: [
                        _fieldLabel('Daily Study Target', theme, cs),
                        const Spacer(),
                        Text(
                          '${_targetHours.toStringAsFixed(1)} hrs',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _targetHours,
                      min: 1,
                      max: 12,
                      divisions: 22,
                      activeColor: cs.primary,
                      inactiveColor: cs.onSurface.withValues(alpha: 0.12),
                      onChanged: (v) =>
                          setState(() => _targetHours = v),
                    ),
                    const SizedBox(height: 16),

                    // Daily blocks target counter
                    Row(
                      children: [
                        _fieldLabel('Daily Blocks Target', theme, cs),
                        const Spacer(),
                        _Counter(
                          value: _targetBlocks,
                          min: 1,
                          max: 10,
                          cs: cs,
                          theme: theme,
                          onChanged: (v) =>
                              setState(() => _targetBlocks = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────

Widget _fieldLabel(String label, ThemeData theme, ColorScheme cs) {
  return Text(
    label,
    style: theme.textTheme.labelMedium?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
    ),
  );
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final ColorScheme cs;
  final ThemeData theme;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.cs,
    required this.theme,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ColorScheme cs;
  final ThemeData theme;
  final ValueChanged<int> onChanged;

  const _Counter({
    required this.value,
    required this.min,
    required this.max,
    required this.cs,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBtn(Icons.remove_rounded, value > min
            ? () {
                HapticFeedback.selectionClick();
                onChanged(value - 1);
              }
            : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
        _iconBtn(Icons.add_rounded, value < max
            ? () {
                HapticFeedback.selectionClick();
                onChanged(value + 1);
              }
            : null),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? cs.primary.withValues(alpha: 0.1)
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? cs.primary
              : cs.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
