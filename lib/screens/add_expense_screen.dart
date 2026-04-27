import 'package:expense_management_app/models/income.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../models/category.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;
  final dynamic index;
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final categories = Hive.box<Category>('categories').values.toList();
    final incomes = Hive.box<Income>('incomes').values.toList();

    if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    if (incomes.isNotEmpty) {
      _selectedIncomeSource = _defaultIncomeSource(incomes);
    }
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _title.text = e.title;
      _amount.text = e.amount.toString();
      _description.text = e.description;
      _date = e.date;
      _selectedCategory = categories.firstWhere(
        (c) => c.name == e.category,
        orElse: () => Category(
          name: e.category,
          iconCode: Icons.category.codePoint,
          subcategories: e.subcategory.isEmpty ? [] : [e.subcategory],
        ),
      );
      _subcategory = e.subcategory;
      _selectedIncomeSource = (e.fromIncomeSource?.isNotEmpty ?? false)
          ? e.fromIncomeSource
          : _defaultIncomeSource(incomes);
    }
  }

  String? _defaultIncomeSource(List<Income> incomes) {
    if (incomes.isEmpty) return null;

    final defaultIncome = incomes.where((income) => income.isDefault);
    return defaultIncome.isNotEmpty
        ? defaultIncome.first.source
        : incomes.first.source;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Preserve existing ID when editing, generate new one for new expenses
      final expenseId = widget.existingExpense?.id ??
          DateTime.now().microsecondsSinceEpoch.toString();
      final incomes = Hive.box<Income>('incomes').values.toList();

      final newExpense = Expense(
        id: expenseId,
        title: _title.text.trim(),
        amount: double.parse(_amount.text.trim()),
        date: _date,
        category: _selectedCategory!.name,
        subcategory:
            _subcategory ??
            ((_selectedCategory!.subcategories.isNotEmpty)
                ? _selectedCategory!.subcategories.first
                : ''),
        description: _description.text.trim(),
        fromIncomeSource:
            _selectedIncomeSource ?? _defaultIncomeSource(incomes) ?? '',
      );

      final box = Hive.box<Expense>('expenses');

      if (widget.index != null) {
        await box.put(widget.index, newExpense);
      } else {
        await box.add(newExpense);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Hive.box<Category>('categories').values.toList();
    final incomeBox = Hive.box<Income>('incomes');
    final incomeSources = incomeBox.values.map((i) => i.source).toList();
    final formCategories = [...categories];
    if (_selectedCategory != null &&
        !formCategories.any((category) => category.name == _selectedCategory!.name)) {
      formCategories.insert(0, _selectedCategory!);
    }
    final selectedCategoryValue = _selectedCategory == null
        ? null
        : formCategories.firstWhere(
            (category) => category.name == _selectedCategory!.name,
          );
    final selectedIncomeValue = incomeSources.contains(_selectedIncomeSource)
        ? _selectedIncomeSource
        : null;

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
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(val.trim()) == null) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Category>(
                    value: selectedCategoryValue,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: formCategories
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
                    validator: (val) =>
                        val == null ? 'Select a category' : null,
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
                      value: selectedIncomeValue,
                      items: incomeSources
                          .map(
                            (src) =>
                                DropdownMenuItem(value: src, child: Text(src)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedIncomeSource = value;
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
                          final today = DateTime.now();
                          final initialDate = _date.isAfter(today)
                              ? today
                              : _date;
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(2020),
                            lastDate: today,
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Expense'),
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
