# Data Models Documentation

## Overview
This directory contains the data models for the Food Ordering application. These models represent the core entities that will be stored in the SQLite database.

## Models

### 1. FoodItem (`food_item.dart`)

Represents a food item that can be ordered.

#### Properties:
- `id` (int?, nullable): Primary key for the food item. Null for new items before insertion.
- `name` (String, required): Name of the food item (e.g., "Pizza", "Burger")
- `cost` (double, required): Price of the food item in dollars

#### Methods:
- `toMap()`: Converts the FoodItem to a Map for database operations
- `fromMap(Map)`: Factory constructor to create FoodItem from database Map
- `copyWith()`: Creates a copy with optional field updates
- `toString()`: String representation for debugging
- `==` and `hashCode`: Equality comparison overrides

#### Database Table: `food_items`
```sql
CREATE TABLE food_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  cost REAL NOT NULL
);
```

#### Usage Example:
```dart
// Create a new food item
final pizza = FoodItem(
  name: 'Pepperoni Pizza',
  cost: 12.99,
);

// Convert to Map for database insertion
final map = pizza.toMap();

// Create from database result
final retrievedPizza = FoodItem.fromMap({
  'id': 1,
  'name': 'Pepperoni Pizza',
  'cost': 12.99,
});
```

---

### 2. OrderPlan (`order_plan.dart`)

Represents a food order plan for a specific date. This is a join entity linking dates with food items.

#### Properties:
- `id` (int?, nullable): Primary key for the order plan record
- `date` (String, required): Date of the order in 'yyyy-MM-dd' format
- `targetCost` (double, required): Daily budget/target cost limit
- `foodItemId` (int, required): Foreign key referencing food_items.id
- `foodItemName` (String?, optional): Name from joined food_items table
- `foodItemCost` (double?, optional): Cost from joined food_items table

#### Methods:
- `toMap()`: Converts OrderPlan to Map for database operations
- `fromMap(Map)`: Factory constructor supporting both simple and JOIN queries
- `copyWith()`: Creates a copy with optional field updates
- `toString()`: String representation for debugging
- `==` and `hashCode`: Equality comparison overrides

#### Database Table: `order_plans`
```sql
CREATE TABLE order_plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  targetCost REAL NOT NULL,
  foodItemId INTEGER NOT NULL,
  FOREIGN KEY (foodItemId) REFERENCES food_items(id) ON DELETE CASCADE
);
```

#### Usage Example:
```dart
// Create a new order plan entry
final orderEntry = OrderPlan(
  date: '2025-11-25',
  targetCost: 50.00,
  foodItemId: 1, // References a food item
);

// Create from JOIN query result (with food details)
final detailedOrder = OrderPlan.fromMap({
  'id': 1,
  'date': '2025-11-25',
  'targetCost': 50.00,
  'foodItemId': 1,
  'foodItemName': 'Pepperoni Pizza',
  'foodItemCost': 12.99,
});
```

---

## Database Relationships

### Entity Relationship Diagram:
```
┌─────────────────┐         ┌─────────────────┐
│  food_items     │         │  order_plans    │
├─────────────────┤         ├─────────────────┤
│ id (PK)         │◄────────│ foodItemId (FK) │
│ name            │    1:N  │ id (PK)         │
│ cost            │         │ date            │
└─────────────────┘         │ targetCost      │
                            └─────────────────┘
```

### Relationship Description:
- **One-to-Many**: One FoodItem can appear in many OrderPlans
- **Foreign Key**: OrderPlan.foodItemId references FoodItem.id
- **Cascade Delete**: If a FoodItem is deleted, related OrderPlans are also deleted

---

## Design Decisions

### 1. **Date Format**
- Stored as String in 'yyyy-MM-dd' format
- Rationale: SQLite doesn't have native DATE type; string format allows easy sorting and comparison
- Format ensures chronological sorting works correctly

### 2. **Separate OrderPlan Records**
- Each selected food item creates a separate OrderPlan record
- Rationale: Simplifies queries and follows normalized database design
- Allows tracking individual items per date

### 3. **Target Cost Duplication**
- targetCost is stored with each OrderPlan record
- Rationale: Captures the budget at the time of order creation
- Historical accuracy if budgets change over time

### 4. **Optional JOIN Fields**
- foodItemName and foodItemCost are optional in OrderPlan
- Rationale: These fields are populated only when performing JOIN queries
- Keeps the model flexible for different query scenarios

### 5. **Nullable ID**
- id field is nullable (int?)
- Rationale: New objects before database insertion don't have IDs yet
- After insertion, the database assigns an auto-incremented ID

---

## Import Usage

Use the barrel file for clean imports:

```dart
import 'package:mobile_assign_3/models/models.dart';

// Now you can use both FoodItem and OrderPlan
final food = FoodItem(name: 'Salad', cost: 8.50);
final order = OrderPlan(
  date: '2025-11-25',
  targetCost: 30.00,
  foodItemId: 1,
);
```

---

## Future Considerations

### Possible Enhancements:
1. **Add categories to FoodItem** (e.g., Breakfast, Lunch, Dinner)
2. **Add nutritional info** (calories, protein, etc.)
3. **Track order status** (planned, ordered, completed)
4. **Add user preferences** for dietary restrictions
5. **Support multiple users** with user_id foreign keys

---

## Testing Considerations

When testing these models:
1. Test `toMap()` and `fromMap()` round-trip conversion
2. Verify equality operators work correctly
3. Test `copyWith()` for partial updates
4. Validate that nullable fields handle null properly
5. Test toString() output for debugging clarity

