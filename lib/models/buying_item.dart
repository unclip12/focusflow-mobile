// =============================================================
// BuyingItem — shopping list item with shop info
// =============================================================

class BuyingItem {
  final String id;
  final String name;
  final String? shop;
  final String? quantity;
  final String? unit;
  final String? category;
  final String? notes;
  final String date; // YYYY-MM-DD
  final bool checked;
  final int sortOrder;
  final String createdAt;

  const BuyingItem({
    required this.id,
    required this.name,
    this.shop,
    this.quantity,
    this.unit,
    this.category,
    this.notes,
    required this.date,
    this.checked = false,
    required this.sortOrder,
    required this.createdAt,
  });

  factory BuyingItem.fromJson(Map<String, dynamic> j) => BuyingItem(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        shop: j['shop'],
        quantity: j['quantity'],
        unit: j['unit'],
        category: j['category'],
        notes: j['notes'],
        date: j['date'] ?? '',
        checked: j['checked'] ?? false,
        sortOrder: j['sortOrder'] ?? 0,
        createdAt: j['createdAt'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (shop != null) 'shop': shop,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (category != null) 'category': category,
        if (notes != null) 'notes': notes,
        'date': date,
        'checked': checked,
        'sortOrder': sortOrder,
        'createdAt': createdAt,
      };

  BuyingItem copyWith({
    String? id,
    String? name,
    String? shop,
    String? quantity,
    String? unit,
    String? category,
    String? notes,
    String? date,
    bool? checked,
    int? sortOrder,
    String? createdAt,
  }) =>
      BuyingItem(
        id: id ?? this.id,
        name: name ?? this.name,
        shop: shop ?? this.shop,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        category: category ?? this.category,
        notes: notes ?? this.notes,
        date: date ?? this.date,
        checked: checked ?? this.checked,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
}
