import 'package:expense_management_app/models/income.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../screens/add_expense_screen.dart';
import '../widgets/expense_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';
  String selectedCategory = 'All';
  DateTimeRange? selectedDateRange;
  bool showSearch = false;

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  bool _isInDateRange(DateTime date, DateTimeRange range) {
    return !date.isBefore(_startOfDay(range.start)) &&
        !date.isAfter(_endOfDay(range.end));
  }

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    final now = DateTime.now();
    selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  void _pickCategoryFilter() async {
    final categoryBox = Hive.box<Category>('categories');
    final categories = ['All', ...categoryBox.values.map((c) => c.name)];

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: categories
                .map(
                  (cat) => ListTile(
                    title: Text(cat),
                    onTap: () => Navigator.pop(context, cat),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        selectedCategory = selected;
      });
    }
  }

  Future<void> _confirmDeleteExpense(dynamic key, Expense expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text(
          'Do you really want to delete "${expense.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await Hive.box<Expense>('expenses').delete(key);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _openExpenseForm({
    Expense? existingExpense,
    dynamic index,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          existingExpense: existingExpense,
          index: index,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseBox = Hive.box<Expense>('expenses');
    final incomeBox = Hive.box<Income>('incomes');

    // Get default income (assuming you have a field like `isDefault` in your Income model)
    final defaultIncome = incomeBox.values.firstWhere(
      (inc) => inc.isDefault,
      orElse: () =>
          Income(source: 'No Default Set', amount: 0.0, isDefault: true),
    );

    // Calculate total spent in current month
    final now = DateTime.now();
    var totalSpent = expenseBox.values
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                showSearch = !showSearch;
                if (!showSearch) searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _pickCategoryFilter,
          ),
        ],
        bottom: showSearch
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search expenses...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // ==== TOP SUMMARY BAR ====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Default Income: ₹${defaultIncome.amount.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Total Spent this month: ₹${totalSpent.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ==== EXPENSE LIST ====
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: expenseBox.listenable(),
              builder: (context, Box<Expense> box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text('No expenses yet.'));
                }

                final now = DateTime.now();
                final filtered =
                    box.toMap().entries.where((entry) {
                      final e = entry.value;

                      // Date filter
                      if (selectedDateRange != null) {
                        if (!_isInDateRange(e.date, selectedDateRange!)) {
                          return false;
                        }
                      } else {
                        if (e.date.isBefore(
                          now.subtract(const Duration(days: 30)),
                        )) {
                          return false;
                        }
                      }

                      // Category filter
                      if (selectedCategory != 'All' &&
                          e.category != selectedCategory) {
                        return false;
                      }

                      // Search filter
                      if (searchQuery.isNotEmpty &&
                          !(e.title.toLowerCase().contains(searchQuery) ||
                              e.category.toLowerCase().contains(searchQuery) ||
                              (e.subcategory?.toLowerCase().contains(
                                    searchQuery,
                                  ) ??
                                  false))) {
                        return false;
                      }

                      return true;
                    }).toList()..sort(
                      (a, b) => b.value.date.compareTo(a.value.date),
                    );
                final curDate = DateTime.now();
                // 🔹 Recalculate totalSpent based on filtered list
                final totalSpent = filtered
                    .where(
                      (exp) => selectedDateRange == null
                          ? (exp.value.date.isAfter(
                                  DateTime(
                                    curDate.year,
                                    curDate.month,
                                    1,
                                  ).subtract(Duration(days: 1)),
                                ) &&
                                exp.value.date.isBefore(
                                  DateTime.now().add(Duration(days: 1)),
                                ))
                              : (exp.value.date.isAfter(
                                  _startOfDay(selectedDateRange!.start)
                                      .subtract(Duration(milliseconds: 1)),
                                ) &&
                                exp.value.date.isBefore(
                                  _endOfDay(selectedDateRange!.end)
                                      .add(Duration(milliseconds: 1)),
                                )),
                    )
                    .fold<double>(
                      0.0,
                      (sum, entry) => sum + entry.value.amount,
                    );
                // 🔹 Update the summary bar with filtered total
                return Column(
                  children: [
                    if (selectedCategory != 'All')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              "Total Spent: ₹${totalSpent.toStringAsFixed(2)}",
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 1),

                    // ==== Expense list ====
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matching expenses.'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final expense = filtered[index].value;
                                final key = filtered[index].key;

                                return ExpenseTile(
                                  expense: expense,
                                  onDelete: () {
                                    _confirmDeleteExpense(key, expense);
                                  },
                                  onTap: () => _openExpenseForm(
                                    existingExpense: expense,
                                    index: key,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openExpenseForm();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
