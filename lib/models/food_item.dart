/// Model class representing a food item in the database
/// 
/// This class handles the data structure for food items including
/// conversion to/from database maps for SQLite operations
class FoodItem {
  final int? id; // Primary key, nullable for new items
  final String name;
  final double cost;

  FoodItem({
    this.id,
    required this.name,
    required this.cost,
  });

  /// Convert FoodItem object to Map for database insertion
  /// Used when inserting or updating records in SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
    };
  }

  /// Create FoodItem object from database Map
  /// Used when retrieving records from SQLite
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      cost: map['cost'] as double,
    );
  }

  /// Create a copy of FoodItem with optional field updates
  /// Useful for update operations
  FoodItem copyWith({
    int? id,
    String? name,
    double? cost,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
    );
  }

  @override
  String toString() {
    return 'FoodItem{id: $id, name: $name, cost: \$$cost}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodItem &&
        other.id == id &&
        other.name == name &&
        other.cost == cost;
  }

  @override
  int get hashCode => Object.hash(id, name, cost);
}
