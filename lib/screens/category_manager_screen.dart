import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final _nameController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _budgetController = TextEditingController();
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

  void _addSubcategory(Category category, int index) {
    final name = _subcategoryController.text.trim();
    if (name.isEmpty) return;

    final box = Hive.box<Category>('categories');

    final updated = Category(
      name: category.name,
      iconCode: category.iconCode,
      budget: category.budget,
      subcategories: [...category.subcategories, name],
    );

    box.putAt(index, updated);
    _subcategoryController.clear();
    setState(() {});
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
                                    controller: _subcategoryController,
                                    decoration: const InputDecoration(
                                      labelText: 'Add Subcategory',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _addSubcategory(c, index),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text(''),
                                onPressed: () => box.deleteAt(index),
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
