import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/income.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  Future<void> _showAddIncomeDialog(
    BuildContext context,
    Box<Income> incomeBox,
  ) async {
    final sourceController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Add Income'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: sourceController,
                    decoration: const InputDecoration(labelText: 'Source'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                  ),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final income = Income(
                    source: sourceController.text.trim(),
                    amount: double.parse(amountController.text.trim()),
                    isDefault: incomeBox.isEmpty,
                  );
                  incomeBox.add(income);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } finally {
      sourceController.dispose();
      amountController.dispose();
    }
  }

  Future<void> _deleteIncome(
    BuildContext context,
    Box<Income> box,
    int index,
  ) async {
    final income = box.getAt(index);
    if (income == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income?'),
        content: Text('Do you really want to delete "${income.source}"?'),
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

    if (shouldDelete != true) return;

    final wasDefault = income.isDefault;
    await income.delete();

    if (wasDefault && box.isNotEmpty) {
      final firstIncome = box.getAt(0);
      if (firstIncome != null) {
        firstIncome.isDefault = true;
        await firstIncome.save();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeBox = Hive.box<Income>('incomes');

    return Scaffold(
      appBar: AppBar(title: const Text('Income Sources')),
      body: ValueListenableBuilder(
        valueListenable: incomeBox.listenable(),
        builder: (context, Box<Income> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No incomes yet.'));
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final income = box.getAt(index)!;
              return ListTile(
                title: Text('${income.source} (${income.amount.toStringAsFixed(2)})'),
                subtitle: income.isDefault ? const Text('Default income') : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.star),
                      color: income.isDefault ? Colors.amber : Colors.grey,
                      onPressed: () {
                        for (var i = 0; i < box.length; i++) {
                          final inc = box.getAt(i);
                          if (inc != null) {
                            inc.isDefault = i == index;
                            inc.save();
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteIncome(context, box, index),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddIncomeDialog(context, incomeBox),
      ),
    );
  }
}
