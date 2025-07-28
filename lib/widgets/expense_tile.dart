import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(expense.title),
      subtitle: Text("${expense.category} • ${expense.date.toLocal().toString().split(' ')[0]}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('\$${expense.amount.toStringAsFixed(2)}'),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],  
      ),
    );
  } 
}
