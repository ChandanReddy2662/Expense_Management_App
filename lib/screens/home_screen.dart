import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../screens/add_expense_screen.dart';
import '../widgets/expense_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Expense>('expenses');
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Expense> box, _) {
          if (box.isEmpty) return const Center(child: Text('No expenses yet.'));
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final expense = box.getAt(index)!;
              print(expense.category);
              final category = Hive.box<Category>('categories').values
                  .firstWhere(
                    (c) => c.name == expense.category,
                    orElse: () => Category(
                      name: 'General',
                      iconCode: Icons.category.codePoint,
                    ),
                  );

              final spent = (box).values
                  .where((e) => e.category == category.name)
                  .fold(0.0, (sum, e) => sum + e.amount);

              // final isOverBudget = category.budget > 0 && spent > category.budget;

              return ExpenseTile(
                expense: expense,
                // icon: category.icon,
                // overBudget: isOverBudget,
                onDelete: () => box.deleteAt(index),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(
                      existingExpense: expense,
                      index: index,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
