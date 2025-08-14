import 'package:expense_management_app/models/income.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../models/category.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;
  final int? index;
  const AddExpenseScreen({super.key, this.existingExpense, this.index});

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
  String? _selectedIncomeSource;

  @override
  void initState() {
    super.initState();
    final categories = Hive.box<Category>('categories').values.toList();
    final incomes = Hive.box<Income>('incomes').values.toList();

    if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    if (incomes.isNotEmpty) {
      _selectedIncomeSource = incomes.where((i) => i.isDefault).first.source;
    }
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _title.text = e.title;
      _amount.text = e.amount.toString();
      _description.text = e.description;
      _date = e.date;
      _selectedCategory = categories.firstWhere(
        (c) => c.name == e.category,
        orElse: () => categories.first,
      );
      _subcategory = e.subcategory;
      _selectedIncomeSource = e.fromIncomeSource!.isNotEmpty? e.fromIncomeSource: incomes.where((i) => i.isDefault).first.source;
      
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;

    final newExpense = Expense(
      title: _title.text,
      amount: double.parse(_amount.text),
      date: _date,
      category: _selectedCategory!.name,
      subcategory:
          _subcategory ??
          ((_selectedCategory!.subcategories.isNotEmpty)
              ? _selectedCategory!.subcategories.first
              : ''),
      description: _description.text,
      fromIncomeSource:
          _selectedIncomeSource ??
          Hive.box<Income>('incomes').values
              .firstWhere(
                (i) => i.isDefault,
                orElse: () => Income(source: '', amount: 0.0),
              )
              .source,
    );

    final box = Hive.box<Expense>('expenses');

    if (widget.index != null) {
      box.putAt(widget.index!, newExpense);
    } else {
      box.add(newExpense);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = Hive.box<Category>('categories').values.toList();
    final incomeBox = Hive.box<Income>('incomes');
    final incomeSources = incomeBox.values.map((i) => i.source).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingExpense == null ? 'Add Expense' : 'Edit Expense',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(c.icon),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                        _subcategory = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_selectedCategory != null &&
                      _selectedCategory!.subcategories.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value:
                          _selectedCategory!.subcategories.contains(
                            _subcategory,
                          )
                          ? _subcategory
                          : _selectedCategory!.subcategories.first,
                      decoration: const InputDecoration(
                        labelText: 'Subcategory',
                        prefixIcon: Icon(Icons.subdirectory_arrow_right),
                      ),
                      items: _selectedCategory!.subcategories
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _subcategory = val),
                    ),
                  const SizedBox(height: 12),
                  if (incomeSources.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Spent From',
                        prefixIcon: Icon(Icons.wallet),
                      ),
                      value: _selectedIncomeSource,
                      items: incomeSources
                          .map(
                            (src) =>
                                DropdownMenuItem(value: src, child: Text(src)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedIncomeSource = value;
                          print(_selectedIncomeSource);
                        });
                      },
                    ),
                  if (_selectedCategory != null &&
                      _selectedCategory!.subcategories.isNotEmpty)
                    const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Date: ${_date.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Expense'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
