import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/income.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

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
                      onPressed: () => income.delete(),
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
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) {
              final sourceController = TextEditingController();
              final amountController = TextEditingController();
              return AlertDialog(
                title: const Text('Add Income'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: sourceController,
                      decoration: const InputDecoration(labelText: 'Source'),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    child: const Text('Save'),
                    onPressed: () {
                      final income = Income(
                        source: sourceController.text,
                        amount: double.tryParse(amountController.text) ?? 0.0,
                        isDefault: incomeBox.isEmpty
                      );
                      incomeBox.add(income);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
