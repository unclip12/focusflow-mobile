// =============================================================
// AddStudyPlanSheet — bottom sheet to create a new StudyPlanItem
// Fields: topic, type (PAGE/VIDEO/HYBRID), pageNumber, target
//         date picker, estimated minutes counter.
// Saves via AppProvider.upsertStudyPlanItem().
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/models/study_plan_item.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';

class AddStudyPlanSheet extends StatefulWidget {
  const AddStudyPlanSheet({super.key});

  /// Convenience helper to show the sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddStudyPlanSheet(),
    );
  }

  @override
  State<AddStudyPlanSheet> createState() => _AddStudyPlanSheetState();
}

class _AddStudyPlanSheetState extends State<AddStudyPlanSheet> {
  final _topicController = TextEditingController();
  final _pageController = TextEditingController();

  String _type = 'PAGE';
  DateTime _targetDate = DateTime.now();
  int _estimatedMinutes = 30;

  bool _saving = false;

  @override
  void dispose() {
    _topicController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;

    setState(() => _saving = true);

    final item = StudyPlanItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(_targetDate),
      type: _type,
      pageNumber: _pageController.text.trim(),
      topic: topic,
      estimatedMinutes: _estimatedMinutes,
      isCompleted: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    await context.read<AppProvider>().upsertStudyPlanItem(item);

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ───────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ──────────────────────────────────────────────
          Text('New Study Plan Item',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // ── Topic input ────────────────────────────────────────
          _InputField(
            controller: _topicController,
            label: 'Topic',
            hint: 'e.g. Brachial Plexus',
          ),
          const SizedBox(height: 12),

          // ── Page number input ──────────────────────────────────
          _InputField(
            controller: _pageController,
            label: 'Page Number',
            hint: 'e.g. 42',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),

          // ── Type selector ──────────────────────────────────────
          Text('Type',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 6),
          Row(
            children: ['PAGE', 'VIDEO', 'HYBRID'].map((t) {
              final selected = _type == t;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.15)
                          : cs.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.4)
                            : cs.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      t[0] + t.substring(1).toLowerCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: selected
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.55),
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // ── Target date ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target Date',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 16,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('d MMM yyyy').format(_targetDate),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // ── Estimated minutes counter ──────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Est. Minutes',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CounterButton(
                            icon: Icons.remove_rounded,
                            onTap: () {
                              if (_estimatedMinutes > 5) {
                                setState(
                                    () => _estimatedMinutes -= 5);
                              }
                            },
                          ),
                          Text(
                            '$_estimatedMinutes',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _CounterButton(
                            icon: Icons.add_rounded,
                            onTap: () =>
                                setState(() => _estimatedMinutes += 5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Save button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                disabledBackgroundColor: cs.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary),
                    )
                  : const Text('Add to Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)),
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: cs.primary),
      ),
    );
  }
}
