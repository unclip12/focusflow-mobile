import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';

Future<bool> insertPlannedBlocksWithConflictHandling({
  required BuildContext context,
  required String dateKey,
  required List<Block> requestedBlocks,
}) async {
  final app = context.read<AppProvider>();
  final analysis = app.analyzePlannedInsertions(dateKey, requestedBlocks);
  if (!analysis.hasConflicts) {
    await app.insertPlannedBlocksWithResolution(
      date: dateKey,
      requestedBlocks: requestedBlocks,
      resolution: PlannedInsertResolutionChoice.keepOverlap,
    );
    return true;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PlannedInsertConflictSheet(
      dateKey: dateKey,
      requestedBlocks: requestedBlocks,
      analysis: analysis,
    ),
  );
  return result ?? false;
}

class PlannedInsertConflictSheet extends StatefulWidget {
  final String dateKey;
  final List<Block> requestedBlocks;
  final PlannedInsertAnalysis analysis;

  const PlannedInsertConflictSheet({
    super.key,
    required this.dateKey,
    required this.requestedBlocks,
    required this.analysis,
  });

  @override
  State<PlannedInsertConflictSheet> createState() =>
      _PlannedInsertConflictSheetState();
}

class _PlannedInsertConflictSheetState
    extends State<PlannedInsertConflictSheet> {
  late PlannedInsertResolutionChoice _resolution;
  late List<_EditablePlacement> _newPlacements;
  late List<_EditablePlacement> _existingPlacements;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resolution = widget.analysis.canSplitCurrentTask
        ? PlannedInsertResolutionChoice.splitCurrentTask
        : PlannedInsertResolutionChoice.moveExistingTasks;
    _newPlacements = widget.requestedBlocks
        .map((block) => _EditablePlacement(block: block, isNew: true))
        .toList();
    _existingPlacements = widget.analysis.conflictingBlocks
        .map((block) => _EditablePlacement(block: block, isNew: false))
        .toList();
  }

  Future<void> _pickStartTime(_EditablePlacement placement) async {
    final currentStart = _toMinutes(placement.block.plannedStartTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentStart ~/ 60,
        minute: currentStart % 60,
      ),
      builder: (pickerContext, child) => MediaQuery(
        data: MediaQuery.of(pickerContext)
            .copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final newStart = (picked.hour * 60) + picked.minute;
    final duration = placement.block.plannedDurationMinutes;
    final updatedBlock = placement.block.copyWith(
      plannedStartTime: _fromMinutes(newStart),
      plannedEndTime: _fromMinutes(newStart + duration),
      plannedDurationMinutes: duration,
      remainingDurationMinutes: duration,
    );

    setState(() {
      _errorText = null;
      final targetList =
          placement.isNew ? _newPlacements : _existingPlacements;
      final index =
          targetList.indexWhere((item) => item.block.id == placement.block.id);
      if (index >= 0) {
        targetList[index] = targetList[index].copyWith(block: updatedBlock);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final app = context.read<AppProvider>();
    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      switch (_resolution) {
        case PlannedInsertResolutionChoice.splitCurrentTask:
          await app.insertPlannedBlocksWithResolution(
            date: widget.dateKey,
            requestedBlocks: _newPlacements.map((item) => item.block).toList(),
            resolution: PlannedInsertResolutionChoice.splitCurrentTask,
          );
          break;
        case PlannedInsertResolutionChoice.keepOverlap:
          await app.insertPlannedBlocksWithResolution(
            date: widget.dateKey,
            requestedBlocks: _newPlacements.map((item) => item.block).toList(),
            resolution: PlannedInsertResolutionChoice.keepOverlap,
          );
          break;
        case PlannedInsertResolutionChoice.moveExistingTasks:
          final editedNewBlocks =
              _newPlacements.map((item) => item.block).toList();
          final editedExistingBlocks =
              _existingPlacements.map((item) => item.block).toList();
          final validation = app.validatePlannedBlockPlacements(
            widget.dateKey,
            [...editedNewBlocks, ...editedExistingBlocks],
            excludedBlockIds:
                editedExistingBlocks.map((block) => block.id).toSet(),
          );
          if (!validation.isValid) {
            setState(() {
              _saving = false;
              _errorText = validation.message;
            });
            return;
          }
          await app.insertPlannedBlocksWithResolution(
            date: widget.dateKey,
            requestedBlocks: editedNewBlocks,
            editedExistingBlocks: editedExistingBlocks,
            resolution: PlannedInsertResolutionChoice.moveExistingTasks,
          );
          break;
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = 'Unable to update the timing right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final recommendedLabel = _formatWindow(
      widget.analysis.recommendedStartMinutes,
      widget.analysis.recommendedEndMinutes,
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resolve time conflict',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recommended free slot: $recommendedLabel',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This timing conflicts with ${widget.analysis.conflictingBlocks.map((block) => block.title).toSet().join(', ')}.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.analysis.canSplitCurrentTask)
                    _resolutionChip(
                      context,
                      label: 'Split current task',
                      value: PlannedInsertResolutionChoice.splitCurrentTask,
                    ),
                  _resolutionChip(
                    context,
                    label: 'Move existing task',
                    value: PlannedInsertResolutionChoice.moveExistingTasks,
                  ),
                  _resolutionChip(
                    context,
                    label: 'Keep overlap',
                    value: PlannedInsertResolutionChoice.keepOverlap,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_resolution == PlannedInsertResolutionChoice.moveExistingTasks)
                        ...[
                          _sectionLabel(context, 'Current task'),
                          const SizedBox(height: 8),
                          ..._newPlacements.map(
                            (placement) => _placementTile(context, placement),
                          ),
                          const SizedBox(height: 12),
                          _sectionLabel(context, 'Conflicting tasks'),
                          const SizedBox(height: 8),
                          ..._existingPlacements.map(
                            (placement) => _placementTile(context, placement),
                          ),
                        ]
                      else if (_resolution ==
                          PlannedInsertResolutionChoice.splitCurrentTask)
                        _infoCard(
                          context,
                          title: 'Respect planned tasks',
                          body:
                              'The new task will be split around the existing planned tasks and keep its full duration.',
                        )
                      else
                        _infoCard(
                          context,
                          title: 'Allow overlap',
                          body:
                              'Both tasks will stay at their selected times and the timeline will keep showing the overlap warning.',
                        ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: TextStyle(
                            color: cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _resolution == PlannedInsertResolutionChoice.moveExistingTasks
                        ? 'Update timing'
                        : 'Save',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resolutionChip(
    BuildContext context, {
    required String label,
    required PlannedInsertResolutionChoice value,
  }) {
    final cs = Theme.of(context).colorScheme;
    final selected = _resolution == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _resolution = value;
          _errorText = null;
        });
      },
      selectedColor: cs.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? cs.primary : cs.onSurface,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _placementTile(BuildContext context, _EditablePlacement placement) {
    final cs = Theme.of(context).colorScheme;
    final block = placement.block;
    final startMinutes = _toMinutes(block.plannedStartTime);
    final endMinutes = _toMinutes(block.plannedEndTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        block.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: placement.isNew
                            ? cs.primary.withValues(alpha: 0.12)
                            : cs.secondary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        placement.isNew ? 'New' : 'Planned',
                        style: TextStyle(
                          color: placement.isNew ? cs.primary : cs.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatMinutes(startMinutes)} - ${_formatMinutes(endMinutes)}  •  ${block.plannedDurationMinutes}m',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _pickStartTime(placement),
            child: const Text('Change start'),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72)),
          ),
        ],
      ),
    );
  }

  String _formatWindow(int startMinutes, int endMinutes) {
    return '${_formatMinutes(startMinutes)} - ${_formatMinutes(endMinutes)}';
  }

  String _formatMinutes(int totalMinutes) {
    final normalized = totalMinutes.clamp(0, 23 * 60 + 59);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    final time = TimeOfDay(hour: hour, minute: minute);
    return time.format(context);
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }

  String _fromMinutes(int totalMinutes) {
    final normalized = totalMinutes.clamp(0, 23 * 60 + 59);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class _EditablePlacement {
  final Block block;
  final bool isNew;

  const _EditablePlacement({
    required this.block,
    required this.isNew,
  });

  _EditablePlacement copyWith({
    Block? block,
    bool? isNew,
  }) {
    return _EditablePlacement(
      block: block ?? this.block,
      isNew: isNew ?? this.isNew,
    );
  }
}
