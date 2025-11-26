import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// DatabaseHelper - Singleton class for managing SQLite database operations
///
/// This class handles all database operations including:
/// - Database initialization and table creation
/// - CRUD operations for FoodItem
/// - CRUD operations for OrderPlan
/// - Seeding initial data
class DatabaseHelper {
  // Singleton pattern implementation
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Private constructor with platform-specific initialization
  DatabaseHelper._internal() {
    // Initialize FFI for Windows/Linux/macOS desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // Factory constructor returns the singleton instance
  factory DatabaseHelper() {
    return _instance;
  }

  /// Get database instance, initialize if not already done
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  /// Creates the database file and tables if they don't exist
  Future<Database> _initDatabase() async {
    // Get the path to the database file
    String path = join(await getDatabasesPath(), 'food_ordering.db');
    
    // Open the database, create tables if needed
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Create database tables
  /// Called automatically when database is created for the first time
  Future<void> _onCreate(Database db, int version) async {
    // Create food_items table
    await db.execute('''
      CREATE TABLE food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost REAL NOT NULL
      )
    ''');

    // Create order_plans table with foreign key
    await db.execute('''
      CREATE TABLE order_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        targetCost REAL NOT NULL,
        foodItemId INTEGER NOT NULL,
        FOREIGN KEY (foodItemId) REFERENCES food_items(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== FOOD ITEM CRUD OPERATIONS ====================

  /// Insert a new food item into the database
  Future<int> insertFoodItem(FoodItem item) async {
    final db = await database;
    return await db.insert('food_items', item.toMap());
  }

  /// Get all food items from the database
  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('food_items');
    
    return List.generate(maps.length, (i) {
      return FoodItem.fromMap(maps[i]);
    });
  }

  /// Get a single food item by ID
  Future<FoodItem?> getFoodItemById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return FoodItem.fromMap(maps.first);
  }

  /// Update an existing food item
  Future<int> updateFoodItem(FoodItem item) async {
    final db = await database;
    return await db.update(
      'food_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete a food item by ID
  /// Note: This will cascade delete related order_plans
  Future<int> deleteFoodItem(int id) async {
    final db = await database;
    return await db.delete(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search food items by name (optional enhancement)
  Future<List<FoodItem>> searchFoodItems(String searchTerm) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'food_items',
      where: 'name LIKE ?',
      whereArgs: ['%$searchTerm%'],
    );
    
    return List.generate(maps.length, (i) {
      return FoodItem.fromMap(maps[i]);
    });
  }

  // ==================== ORDER PLAN CRUD OPERATIONS ====================

  /// Insert a new order plan entry
  Future<int> insertOrderPlan(OrderPlan orderPlan) async {
    final db = await database;
    return await db.insert('order_plans', orderPlan.toMap());
  }

  /// Get all order plans for a specific date (with food item details via JOIN)
  Future<List<OrderPlan>> getOrdersForDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        op.id,
        op.date,
        op.targetCost,
        op.foodItemId,
        fi.name AS foodItemName,
        fi.cost AS foodItemCost
      FROM order_plans op
      INNER JOIN food_items fi ON op.foodItemId = fi.id
      WHERE op.date = ?
      ORDER BY fi.name
    ''', [date]);
    
    return List.generate(maps.length, (i) {
      return OrderPlan.fromMap(maps[i]);
    });
  }

  /// Get all unique dates that have order plans
  Future<List<String>> getAllOrderDates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT date
      FROM order_plans
      ORDER BY date DESC
    ''');
    
    return List.generate(maps.length, (i) {
      return maps[i]['date'] as String;
    });
  }

  /// Delete all order plans for a specific date
  Future<int> deleteOrdersForDate(String date) async {
    final db = await database;
    return await db.delete(
      'order_plans',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  /// Get the total cost for a specific date
  Future<double> getTotalCostForDate(String date) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(fi.cost) as total
      FROM order_plans op
      INNER JOIN food_items fi ON op.foodItemId = fi.id
      WHERE op.date = ?
    ''', [date]);
    
    if (result.isEmpty || result.first['total'] == null) {
      return 0.0;
    }
    return result.first['total'] as double;
  }

  /// Check if an order plan exists for a specific date
  Future<bool> hasOrdersForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'order_plans',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }

  /// Close the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
