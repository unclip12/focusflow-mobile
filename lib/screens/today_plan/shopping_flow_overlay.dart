// =============================================================
// ShoppingFlowOverlay — Full-screen shopping checklist popup
// Shows buying items sorted by shop or by list order.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/buying_item.dart';

class ShoppingFlowOverlay extends StatefulWidget {
  final String dateKey;
  const ShoppingFlowOverlay({super.key, required this.dateKey});

  @override
  State<ShoppingFlowOverlay> createState() => _ShoppingFlowOverlayState();
}

class _ShoppingFlowOverlayState extends State<ShoppingFlowOverlay> {
  bool _sortByShop = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final items = app.getBuyingItemsForDate(widget.dateKey);
    final checkedCount = items.where((i) => i.checked).length;

    return Material(
      color: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shopping List',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          '$checkedCount of ${items.length} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sort toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('List', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: true, label: Text('By Shop', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {_sortByShop},
                    onSelectionChanged: (v) => setState(() => _sortByShop = v.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: cs.error),
                  ),
                ],
              ),
            ),

            // ── Progress bar ──────────────────────────────────
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: items.isEmpty ? 0 : checkedCount / items.length,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ── Items ─────────────────────────────────────────
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🛍️', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'No items in your shopping list',
                            style: TextStyle(
                              fontSize: 15,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add items from the Buying tab',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _sortByShop
                      ? _ShopGroupedList(items: items, onToggle: _toggleItem)
                      : _FlatList(items: items, onToggle: _toggleItem),
            ),

            // ── Done button ───────────────────────────────────
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      checkedCount == items.length ? 'All Done! 🎉' : 'Close',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleItem(BuyingItem item) {
    final app = context.read<AppProvider>();
    app.upsertBuyingItem(item.copyWith(checked: !item.checked));
  }
}

// ── Flat list view ──────────────────────────────────────────────
class _FlatList extends StatelessWidget {
  final List<BuyingItem> items;
  final ValueChanged<BuyingItem> onToggle;

  const _FlatList({required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final sorted = List<BuyingItem>.from(items)
      ..sort((a, b) {
        if (a.checked != b.checked) return a.checked ? 1 : -1;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sorted.length,
      itemBuilder: (context, i) => _ItemTile(item: sorted[i], onToggle: onToggle),
    );
  }
}

// ── Shop grouped list view ──────────────────────────────────────
class _ShopGroupedList extends StatelessWidget {
  final List<BuyingItem> items;
  final ValueChanged<BuyingItem> onToggle;

  const _ShopGroupedList({required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grouped = <String, List<BuyingItem>>{};
    for (final item in items) {
      final shop = item.shop ?? 'Unspecified';
      grouped.putIfAbsent(shop, () => []).add(item);
    }

    final shops = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: shops.length,
      itemBuilder: (context, i) {
        final shop = shops[i];
        final shopItems = grouped[shop]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.store_rounded, size: 16,
                      color: cs.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    shop,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${shopItems.where((i) => i.checked).length}/${shopItems.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            ...shopItems.map((item) => _ItemTile(item: item, onToggle: onToggle)),
          ],
        );
      },
    );
  }
}

// ── Item tile ───────────────────────────────────────────────────
class _ItemTile extends StatelessWidget {
  final BuyingItem item;
  final ValueChanged<BuyingItem> onToggle;

  const _ItemTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: item.checked
            ? cs.primaryContainer.withValues(alpha: 0.2)
            : cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: item.checked,
          onChanged: (_) => onToggle(item),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          activeColor: const Color(0xFF10B981),
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
        subtitle: _buildSubtitle(cs),
        trailing: item.quantity != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget? _buildSubtitle(ColorScheme cs) {
    final parts = <String>[];
    if (item.shop != null) parts.add('📍 ${item.shop}');
    if (item.notes != null) parts.add(item.notes!);
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' • '),
      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
    );
  }
}
