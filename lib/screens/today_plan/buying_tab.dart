// =============================================================
// BuyingTab — Shopping checklist with shop info + sort options
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/buying_item.dart';
import 'shopping_flow_overlay.dart';

class BuyingTab extends StatelessWidget {
  final String dateKey;
  const BuyingTab({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final items = app.getBuyingItemsForDate(dateKey);
    final checkedCount = items.where((i) => i.checked).length;

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                '$checkedCount of ${items.length} items',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              if (items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openShoppingFlow(context),
                  icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                  label: const Text('Go Shopping', style: TextStyle(fontSize: 12)),
                ),
              TextButton.icon(
                onPressed: () => _showAddItem(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),

        // ── Progress ──────────────────────────────────────────
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: items.isEmpty ? 0 : checkedCount / items.length,
                minHeight: 4,
                backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
              ),
            ),
          ),

        // ── Items ─────────────────────────────────────────────
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🛒', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'No buying items yet',
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add an item',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.delete_rounded, color: cs.error),
                      ),
                      onDismissed: (_) => app.deleteBuyingItem(item.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: item.checked
                              ? const Color(0xFF10B981).withValues(alpha: 0.05)
                              : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CheckboxListTile(
                          value: item.checked,
                          onChanged: (_) {
                            app.upsertBuyingItem(item.copyWith(checked: !item.checked));
                          },
                          activeColor: const Color(0xFF10B981),
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: item.checked ? TextDecoration.lineThrough : null,
                              color: item.checked
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface,
                            ),
                          ),
                          subtitle: _buildSubtitle(item, cs),
                          secondary: item.quantity != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                )
                              : null,
                          dense: true,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget? _buildSubtitle(BuyingItem item, ColorScheme cs) {
    final parts = <String>[];
    if (item.shop != null) parts.add('📍 ${item.shop}');
    if (item.notes != null) parts.add(item.notes!);
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' • '),
      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
    );
  }

  void _openShoppingFlow(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => ShoppingFlowOverlay(dateKey: dateKey),
    );
  }

  void _showAddItem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddBuyingSheet(dateKey: dateKey),
    );
  }
}

// ── Add Buying Item Sheet ───────────────────────────────────────
class _AddBuyingSheet extends StatefulWidget {
  final String dateKey;
  const _AddBuyingSheet({required this.dateKey});

  @override
  State<_AddBuyingSheet> createState() => _AddBuyingSheetState();
}

class _AddBuyingSheetState extends State<_AddBuyingSheet> {
  final _nameCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _unit;
  final _uuid = const Uuid();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shopCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final app = context.read<AppProvider>();
    final items = app.getBuyingItemsForDate(widget.dateKey);

    final item = BuyingItem(
      id: _uuid.v4(),
      name: _nameCtrl.text.trim(),
      shop: _shopCtrl.text.isNotEmpty ? _shopCtrl.text.trim() : null,
      quantity: _qtyCtrl.text.isNotEmpty ? _qtyCtrl.text.trim() : null,
      unit: _unit,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      date: widget.dateKey,
      sortOrder: items.length,
      createdAt: DateTime.now().toIso8601String(),
    );
    app.upsertBuyingItem(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add Item', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
          )),
          const SizedBox(height: 16),

          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Item name',
              hintText: 'e.g., Milk',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _shopCtrl,
            decoration: InputDecoration(
              labelText: 'Shop (optional)',
              hintText: 'e.g., DMart',
              prefixIcon: const Icon(Icons.store_rounded, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  items: ['kg', 'g', 'L', 'ml', 'pcs', 'pkt']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _unit = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
