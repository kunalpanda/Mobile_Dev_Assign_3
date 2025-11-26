import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class ManageFoodScreen extends StatefulWidget {
  const ManageFoodScreen({super.key});

  @override
  State<ManageFoodScreen> createState() => _ManageFoodScreenState();
}

class _ManageFoodScreenState extends State<ManageFoodScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<FoodItem> _foodItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    setState(() => _isLoading = true);
    
    try {
      final items = await _dbHelper.getAllFoodItems();
      setState(() {
        _foodItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading food items: $e')),
        );
      }
    }
  }

  Future<void> _showAddEditDialog({FoodItem? item}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final costController = TextEditingController(
      text: item != null ? item.cost.toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Food Item' : 'Edit Food Item'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a food name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Cost (\$)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a cost';
                  }
                  final cost = double.tryParse(value);
                  if (cost == null || cost <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: Text(item == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      final cost = double.parse(costController.text);

      try {
        if (item == null) {
          // Add new item
          final newItem = FoodItem(name: name, cost: cost);
          await _dbHelper.insertFoodItem(newItem);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "$name" successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Update existing item
          final updatedItem = FoodItem(
            id: item.id,
            name: name,
            cost: cost,
          );
          await _dbHelper.updateFoodItem(updatedItem);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updated "$name" successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        _loadFoodItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteItem(FoodItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food Item?'),
        content: Text(
          'Are you sure you want to delete "${item.name}"?\n\n'
          'This will also delete any order plans that include this item.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteFoodItem(item.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${item.name}" successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadFoodItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Food Items'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _foodItems.isEmpty
              ? _buildEmptyState()
              : _buildFoodList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Food Item'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'No Food Items Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the button below to add your first food item!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodList() {
    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.restaurant,
                color: Colors.deepPurple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '${_foodItems.length} Food Items',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Food items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _foodItems.length,
            itemBuilder: (context, index) {
              final item = _foodItems[index];
              return _buildFoodItemCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItemCard(FoodItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F7FC),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Food icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fastfood,
                color: Colors.cyan.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Food details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${item.cost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                IconButton(
                  onPressed: () => _showAddEditDialog(item: item),
                  icon: const Icon(Icons.edit),
                  color: Colors.deepPurple,
                  tooltip: 'Edit',
                ),
                // Delete button
                IconButton(
                  onPressed: () => _deleteItem(item),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
