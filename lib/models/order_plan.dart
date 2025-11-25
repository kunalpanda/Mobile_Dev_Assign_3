/// Model class representing an order plan in the database
/// 
/// An order plan represents a collection of food items selected for a specific date
/// with a target budget. This is a join entity that links dates with food items.
class OrderPlan {
  final int? id; // Primary key, nullable for new records
  final String date; // Date in 'yyyy-MM-dd' format
  final double targetCost; // Daily budget limit
  final int foodItemId; // Foreign key to food_items table
  
  // Optional fields populated from JOIN queries
  final String? foodItemName; // Name of the food item (from food_items table)
  final double? foodItemCost; // Cost of the food item (from food_items table)

  OrderPlan({
    this.id,
    required this.date,
    required this.targetCost,
    required this.foodItemId,
    this.foodItemName,
    this.foodItemCost,
  });

  /// Convert OrderPlan object to Map for database insertion
  /// Only includes fields that exist in the order_plans table
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'targetCost': targetCost,
      'foodItemId': foodItemId,
    };
  }

  /// Create OrderPlan object from database Map
  /// Handles both simple queries and JOIN queries with food item details
  factory OrderPlan.fromMap(Map<String, dynamic> map) {
    return OrderPlan(
      id: map['id'] as int?,
      date: map['date'] as String,
      targetCost: map['targetCost'] as double,
      foodItemId: map['foodItemId'] as int,
      // Optional fields from JOIN queries
      foodItemName: map['foodItemName'] as String?,
      foodItemCost: map['foodItemCost'] as double?,
    );
  }

  /// Create a copy of OrderPlan with optional field updates
  OrderPlan copyWith({
    int? id,
    String? date,
    double? targetCost,
    int? foodItemId,
    String? foodItemName,
    double? foodItemCost,
  }) {
    return OrderPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      targetCost: targetCost ?? this.targetCost,
      foodItemId: foodItemId ?? this.foodItemId,
      foodItemName: foodItemName ?? this.foodItemName,
      foodItemCost: foodItemCost ?? this.foodItemCost,
    );
  }

  @override
  String toString() {
    return 'OrderPlan{id: $id, date: $date, targetCost: \$$targetCost, '
        'foodItemId: $foodItemId, foodItemName: $foodItemName, '
        'foodItemCost: \$${foodItemCost ?? 0.0}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderPlan &&
        other.id == id &&
        other.date == date &&
        other.targetCost == targetCost &&
        other.foodItemId == foodItemId;
  }

  @override
  int get hashCode => Object.hash(id, date, targetCost, foodItemId);
}
