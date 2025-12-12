class QuotationItem {
  final String description;
  final double amount;
  final int quantity;

  QuotationItem({
    required this.description,
    required this.amount,
    required this.quantity,
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'quantity': quantity,
    };
  }
}

class Quotation {
  final List<QuotationItem> items;
  final double totalAmount;
  final String? notes;
  final String status;
  final DateTime? generatedAt;

  Quotation({
    required this.items,
    required this.totalAmount,
    this.notes,
    required this.status,
    this.generatedAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      items: (json['items'] as List)
          .map((i) => QuotationItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
      status: json['status'] as String,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'notes': notes,
      'status': status,
      'generatedAt': generatedAt?.toIso8601String(),
    };
  }
}
