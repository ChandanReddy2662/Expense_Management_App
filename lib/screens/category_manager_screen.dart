import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/expense.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final Map<dynamic, TextEditingController> _subcategoryControllers = {};
  IconData _selectedIcon = Icons.category;
  bool _showForm = false;

  final icons = [
    Icons.fastfood,
    Icons.flight,
    Icons.shopping_bag,
    Icons.receipt,
    Icons.home,
    Icons.savings,
    Icons.category,
  ];

  void _addCategory() {
    final name = _nameController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    if (name.isEmpty) return;

    final category = Category(
      name: name,
      iconCode: _selectedIcon.codePoint,
      budget: budget,
    );

    Hive.box<Category>('categories').add(category);

    _nameController.clear();
    _budgetController.clear();
    setState(() {});
  }

  TextEditingController _subcategoryControllerFor(dynamic key) {
    return _subcategoryControllers.putIfAbsent(
      key,
      () => TextEditingController(),
    );
  }

  void _addSubcategory(Category category, int index, dynamic key) {
    final controller = _subcategoryControllerFor(key);
    final name = controller.text.trim();
    if (name.isEmpty) return;
    if (category.subcategories
        .any((sub) => sub.toLowerCase() == name.toLowerCase())) {
      return;
    }

    final box = Hive.box<Category>('categories');

    final updated = Category(
      name: category.name,
      iconCode: category.iconCode,
      budget: category.budget,
      subcategories: [...category.subcategories, name],
    );

    box.putAt(index, updated);
    controller.clear();
    setState(() {});
  }

  Future<void> _deleteCategory(Box<Category> box, int index) async {
    final category = box.getAt(index);
    if (category == null) return;

    final hasExpenses = Hive.box<Expense>('expenses').values.any(
      (expense) => expense.category == category.name,
    );

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          hasExpenses
              ? '"${category.name}" is used by existing expenses. Delete it anyway? Existing expenses will keep this category name.'
              : 'Do you really want to delete "${category.name}"?',
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
      final key = box.keyAt(index);
      await box.deleteAt(index);
      _subcategoryControllers.remove(key)?.dispose();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    for (final controller in _subcategoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _deleteSubcategory(Category category, int categoryIndex, int subIndex) {
    final updatedSubcategories = List<String>.from(category.subcategories)
      ..removeAt(subIndex);

    final updated = Category(
      name: category.name,
      iconCode: category.iconCode,
      budget: category.budget,
      subcategories: updatedSubcategories,
    );

    Hive.box<Category>('categories').putAt(categoryIndex, updated);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_showForm)
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Budget (optional)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Select Icon"),
                      Wrap(
                        spacing: 12,
                        children: icons.map((icon) {
                          return ChoiceChip(
                            label: Icon(icon),
                            selected: _selectedIcon == icon,
                            onSelected: (_) =>
                                setState(() => _selectedIcon = icon),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Category'),
                          onPressed: _addCategory,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Category>('categories').listenable(),
                builder: (_, Box<Category> box, __) {
                  if (box.isEmpty) {
                    return const Center(
                      child: Text('No categories added yet.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (_, index) {
                      final c = box.getAt(index)!;
                      final key = box.keyAt(index);
                      final subcategoryController =
                          _subcategoryControllerFor(key);
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ExpansionTile(
                          leading: Icon(
                            IconData(c.iconCode, fontFamily: 'MaterialIcons'),
                          ),
                          title: Text(c.name),
                          subtitle: c.budget > 0
                              ? Text('Budget: ₹${c.budget.toStringAsFixed(2)}')
                              : null,
                          childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          children: [
                            if (c.subcategories.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  c.subcategories.length,
                                  (subIndex) => Chip(
                                    label: Text(c.subcategories[subIndex]),
                                    deleteIcon: const Icon(Icons.close),
                                    onDeleted: () => _deleteSubcategory(
                                      c,
                                      index,
                                      subIndex,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: subcategoryController,
                                    decoration: const InputDecoration(
                                      labelText: 'Add Subcategory',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () =>
                                      _addSubcategory(c, index, key),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text(''),
                                onPressed: () => _deleteCategory(box, index),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showForm = !_showForm;
          });
        },
        child: Icon(_showForm ? Icons.close : Icons.add),
      ),
    );
  }
}
