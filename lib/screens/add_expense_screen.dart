import 'package:expense_management_app/models/income.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/frequent_expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;
  final FrequentExpense? frequentExpense;
  final dynamic frequentExpenseKey;
  final bool editFrequentExpense;
  final dynamic index;
  const AddExpenseScreen({
    super.key,
    this.existingExpense,
    this.frequentExpense,
    this.frequentExpenseKey,
    this.editFrequentExpense = false,
    this.index,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _shortcutName = TextEditingController();
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
    } else if (widget.frequentExpense != null) {
      _shortcutName.text = widget.frequentExpense!.name;
      _applyFrequentExpense(
        widget.frequentExpense!,
        resetDate: false,
        notify: false,
      );
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
    _shortcutName.dispose();
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
      final expenseId =
          widget.existingExpense?.id ??
          DateTime.now().microsecondsSinceEpoch.toString();
      final incomes = Hive.box<Income>('incomes').values.toList();

      final newExpense = Expense(
        id: expenseId,
        title: _title.text.trim(),
        amount: double.parse(_amount.text.trim()),
        date: _date,
        category: _selectedCategory!.name,
        subcategory: _resolvedSubcategory(),
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

  Future<void> _saveFrequentExpenseChanges() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() ||
        _selectedCategory == null ||
        _shortcutName.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final shortcut = FrequentExpense(
        name: _shortcutName.text.trim(),
        title: _title.text.trim(),
        amount: double.parse(_amount.text.trim()),
        category: _selectedCategory!.name,
        subcategory: _resolvedSubcategory(),
        description: _description.text.trim(),
        fromIncomeSource: _selectedIncomeSource ?? '',
      );

      final box = Hive.box<FrequentExpense>('frequent_expenses');
      if (widget.frequentExpenseKey != null) {
        await box.put(widget.frequentExpenseKey, shortcut);
      } else {
        await box.add(shortcut);
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

  String _resolvedSubcategory() {
    if (_selectedCategory == null) return '';
    if (_subcategory != null &&
        _selectedCategory!.subcategories.contains(_subcategory)) {
      return _subcategory!;
    }
    return _selectedCategory!.subcategories.isNotEmpty
        ? _selectedCategory!.subcategories.first
        : '';
  }

  Category _categoryForName(List<Category> categories, String categoryName) {
    return categories.firstWhere(
      (category) => category.name == categoryName,
      orElse: () =>
          Category(name: categoryName, iconCode: Icons.category.codePoint),
    );
  }

  void _applyFrequentExpense(
    FrequentExpense frequentExpense, {
    bool resetDate = true,
    bool notify = true,
  }) {
    final categories = Hive.box<Category>('categories').values.toList();
    final incomes = Hive.box<Income>('incomes').values.toList();
    final incomeSources = incomes.map((income) => income.source).toSet();
    final category = _categoryForName(categories, frequentExpense.category);

    void applyValues() {
      _title.text = frequentExpense.title;
      _amount.text = frequentExpense.amount.toString();
      _description.text = frequentExpense.description;
      _selectedCategory = category;
      _subcategory =
          category.subcategories.contains(frequentExpense.subcategory)
          ? frequentExpense.subcategory
          : null;
      _selectedIncomeSource =
          incomeSources.contains(frequentExpense.fromIncomeSource)
          ? frequentExpense.fromIncomeSource
          : _defaultIncomeSource(incomes);
      if (resetDate) {
        _date = DateTime.now();
      }
    }

    if (notify) {
      setState(applyValues);
    } else {
      applyValues();
    }
  }

  Future<void> _saveAsFrequentExpense() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }

    final nameController = TextEditingController(text: _title.text.trim());
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Frequently Used Expense'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Shortcut name',
            prefixIcon: Icon(Icons.bookmark_add),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save Shortcut'),
          ),
        ],
      ),
    );
    nameController.dispose();

    if (name == null || name.isEmpty) return;

    final shortcut = FrequentExpense(
      name: name,
      title: _title.text.trim(),
      amount: double.parse(_amount.text.trim()),
      category: _selectedCategory!.name,
      subcategory: _resolvedSubcategory(),
      description: _description.text.trim(),
      fromIncomeSource: _selectedIncomeSource ?? '',
    );

    await Hive.box<FrequentExpense>('frequent_expenses').add(shortcut);

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" saved as frequently used.')),
      );
    }
  }

  Future<void> _deleteFrequentExpense(dynamic key, String name) async {
    await Hive.box<FrequentExpense>('frequent_expenses').delete(key);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" removed from shortcuts.')),
      );
    }
  }

  Future<void> _editFrequentExpense(
    dynamic key,
    FrequentExpense frequentExpense,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          frequentExpense: frequentExpense,
          frequentExpenseKey: key,
          editFrequentExpense: true,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Hive.box<Category>('categories').values.toList();
    final incomeBox = Hive.box<Income>('incomes');
    final frequentExpenseBox = Hive.box<FrequentExpense>('frequent_expenses');
    final incomeSources = incomeBox.values.map((i) => i.source).toList();
    final frequentExpenses = frequentExpenseBox.toMap().entries.toList()
      ..sort((a, b) => a.value.name.compareTo(b.value.name));
    final formCategories = [...categories];
    if (_selectedCategory != null &&
        !formCategories.any(
          (category) => category.name == _selectedCategory!.name,
        )) {
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

    final isEditingFrequentExpense = widget.editFrequentExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditingFrequentExpense
              ? 'Edit Frequently Used'
              : widget.existingExpense == null
              ? 'Add Expense'
              : 'Edit Expense',
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
                  if (isEditingFrequentExpense) ...[
                    TextFormField(
                      controller: _shortcutName,
                      decoration: const InputDecoration(
                        labelText: 'Shortcut name',
                        prefixIcon: Icon(Icons.bookmark),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
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
                    onPressed: _isSaving
                        ? null
                        : isEditingFrequentExpense
                        ? _saveFrequentExpenseChanges
                        : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : isEditingFrequentExpense
                          ? 'Update Shortcut'
                          : 'Save Expense',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  if (isEditingFrequentExpense) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Expense from Shortcut'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                  if (widget.existingExpense == null &&
                      !isEditingFrequentExpense) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _saveAsFrequentExpense,
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('Save as Frequently Used'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    if (frequentExpenses.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Frequently Used',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ...frequentExpenses.map((entry) {
                        final frequentExpense = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.bookmark),
                            title: Text(frequentExpense.name),
                            subtitle: Text(
                              '${frequentExpense.title} - Rs. '
                              '${frequentExpense.amount.toStringAsFixed(2)}',
                            ),
                            onTap: () => _applyFrequentExpense(frequentExpense),
                            trailing: SizedBox(
                              width: 96,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit shortcut',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _editFrequentExpense(
                                      entry.key,
                                      frequentExpense,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove shortcut',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteFrequentExpense(
                                      entry.key,
                                      frequentExpense.name,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
