import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _budgetController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  double _targetCost = 0.0;
  List<FoodItem> _allFoodItems = [];
  Set<int> _selectedItemIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodItems() async {
    setState(() => _isLoading = true);
    
    try {
      final items = await _dbHelper.getAllFoodItems();
      setState(() {
        _allFoodItems = items;
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

  double _calculateTotal() {
    double total = 0.0;
    for (var item in _allFoodItems) {
      if (_selectedItemIds.contains(item.id)) {
        total += item.cost;
      }
    }
    return total;
  }

  bool _canSelectItem(FoodItem item) {
    // If already selected, can always deselect
    if (_selectedItemIds.contains(item.id)) {
      return true;
    }
    
    // If no budget set, can't select
    if (_targetCost <= 0) {
      return false;
    }
    
    // Check if adding this item would exceed budget
    double currentTotal = _calculateTotal();
    return (currentTotal + item.cost) <= _targetCost;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      // Check if order already exists for this date
      final dateString = DateFormat('yyyy-MM-dd').format(picked);
      final hasOrders = await _dbHelper.hasOrdersForDate(dateString);
      
      if (hasOrders && mounted) {
        // Show confirmation dialog
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace Existing Plan?'),
            content: Text(
              'An order plan already exists for ${DateFormat('MMMM d, yyyy').format(picked)}.\n\n'
              'Do you want to replace it with a new plan?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Replace'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          setState(() => _selectedDate = picked);
        }
      } else {
        setState(() => _selectedDate = picked);
      }
    }
  }

  void _onBudgetChanged(String value) {
    final double? budget = double.tryParse(value);
    setState(() {
      _targetCost = budget ?? 0.0;
      // Clear selections if new budget doesn't allow current total
      if (_calculateTotal() > _targetCost) {
        _selectedItemIds.clear();
      }
    });
  }

  void _onItemToggled(FoodItem item, bool? checked) {
    setState(() {
      if (checked == true) {
        if (_canSelectItem(item)) {
          _selectedItemIds.add(item.id!);
        } else {
          // Show message that budget would be exceeded
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adding this item would exceed your budget'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _selectedItemIds.remove(item.id!);
      }
    });
  }

  Future<void> _saveOrderPlan() async {
    // Validation
    if (_targetCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target budget')),
      );
      return;
    }

    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one food item')),
      );
      return;
    }

    final double total = _calculateTotal();
    if (total > _targetCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total cost exceeds target budget')),
      );
      return;
    }

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Delete existing orders for this date (if any)
      await _dbHelper.deleteOrdersForDate(dateString);
      
      // Insert new order plans
      for (var itemId in _selectedItemIds) {
        final orderPlan = OrderPlan(
          date: dateString,
          targetCost: _targetCost,
          foodItemId: itemId,
        );
        await _dbHelper.insertOrderPlan(orderPlan);
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order plan saved for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}!'
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to home
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving order plan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTotal = _calculateTotal();
    final isOverBudget = _targetCost > 0 && currentTotal > _targetCost;
    final budgetPercentage = _targetCost > 0 ? (currentTotal / _targetCost).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order Plan'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Picker
                        _buildDatePicker(),
                        const SizedBox(height: 20),
                        
                        // Budget Input
                        _buildBudgetInput(),
                        const SizedBox(height: 30),
                        
                        // Food Items List Header
                        Text(
                          'Select Food Items:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFoodItemsList(),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Bar with Summary
                _buildBottomBar(currentTotal, isOverBudget, budgetPercentage),
              ],
            ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
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
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.deepPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetInput() {
    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    color: Colors.cyan.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Budget',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _budgetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: _onBudgetChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_targetCost > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Remaining: \$${(_targetCost - _calculateTotal()).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  color: _calculateTotal() > _targetCost ? Colors.red : Colors.cyan.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemsList() {
    return Column(
      children: _allFoodItems.map((item) {
        final isSelected = _selectedItemIds.contains(item.id);
        final canSelect = _canSelectItem(item);
        final isDisabled = !canSelect && !isSelected;

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
                blurRadius: isDisabled ? 4 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: isDisabled ? null : (checked) => _onItemToggled(item, checked),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            title: Text(
              item.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDisabled ? Colors.grey.shade400 : Colors.black87,
                height: 1.3,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '\$${item.cost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  color: isDisabled ? Colors.grey.shade400 : Colors.cyan.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            secondary: isDisabled
                ? Icon(Icons.lock, color: Colors.grey.shade400, size: 28)
                : null,
            activeColor: Colors.deepPurple,
            enabled: !isDisabled,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(double currentTotal, bool isOverBudget, double budgetPercentage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar
            if (_targetCost > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: budgetPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? Colors.red : Colors.cyan,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${_selectedItemIds.length} items',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: \$${currentTotal.toStringAsFixed(2)}${_targetCost > 0 ? ' / \$${_targetCost.toStringAsFixed(2)}' : ''}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _selectedItemIds.isEmpty || isOverBudget || _targetCost <= 0
                      ? null
                      : _saveOrderPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    isOverBudget ? 'Over Budget!' : 'Save Plan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
