import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../models/category.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  DateTime _date = DateTime.now();
  Category? _selectedCategory;
  String? _subcategory;

  @override
  void initState() {
    super.initState();
    final categories = Hive.box<Category>('categories').values.toList();
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;
    final expense = Expense(
      title: _title.text,
      amount: double.parse(_amount.text),
      date: _date,
      category: _selectedCategory!.name,
      subcategory: _subcategory ?? '',
      description: _description.text,
    );
    Hive.box<Expense>('expenses').add(expense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = Hive.box<Category>('categories').values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title'), validator: (val) => val!.isEmpty ? 'Required' : null),
            TextFormField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount'), validator: (val) => val!.isEmpty ? 'Required' : null),
            DropdownButtonFormField<Category>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Row(children: [Icon(c.icon), const SizedBox(width: 8), Text(c.name)]))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                  _subcategory = null;
                });
              },
            ),
            if (_selectedCategory != null && _selectedCategory!.subcategories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _subcategory,
                decoration: const InputDecoration(labelText: 'Subcategory'),
                items: _selectedCategory!.subcategories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _subcategory = val),
              ),
            TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description (optional)')),
            Row(children: [
              Text('Date: ${_date.toLocal()}'.split(' ')[0]),
              const Spacer(),
              TextButton(onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                if (picked != null) setState(() => _date = picked);
              }, child: const Text('Pick Date'))
            ]),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save Expense'))
          ]),
        ),
      ),
    );
  }
}
