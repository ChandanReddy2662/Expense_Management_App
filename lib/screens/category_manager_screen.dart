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
  IconData _icon = Icons.category;
  double _budget = 0.0;

  void _addCategory() {
    if (_nameController.text.isEmpty) return;
    final cat = Category(
      name: _nameController.text,
      iconCode: _icon.codePoint,
      budget: _budget,
    );
    Hive.box<Category>('categories').add(cat);
    _nameController.clear();
    setState(() => _budget = 0);
  }

  void _addSubcategory(Category category) {
    if (_subcategoryController.text.isEmpty) return;

    final box = Hive.box<Category>('categories');
    final index = category.key as int; // Safe to cast in normal Hive usage

    final updated = Category(
      name: category.name,
      iconCode: category.iconCode,
      budget: category.budget,
      subcategories: [...category.subcategories, _subcategoryController.text],
    );

    box.putAt(index, updated); // Replace the old category with the updated one

    _subcategoryController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.fastfood,
      Icons.flight,
      Icons.shopping_bag,
      Icons.receipt,
      Icons.home,
      Icons.savings,
      Icons.category,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Column(
        children: [
          ListTile(
            title: TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            trailing: DropdownButton<IconData>(
              value: _icon,
              items: icons
                  .map((i) => DropdownMenuItem(value: i, child: Icon(i)))
                  .toList(),
              onChanged: (i) => setState(() => _icon = i!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Budget (optional)',
              ),
              onChanged: (val) => _budget = double.tryParse(val) ?? 0,
            ),
          ),
          ElevatedButton(
            onPressed: _addCategory,
            child: const Text('Add Category'),
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Category>('categories').listenable(),
              builder: (_, box, __) {
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (_, i) {
                    final c = box.getAt(i)!;
                    return ExpansionTile(
                      leading: Icon(c.icon),
                      title: Text(c.name),
                      subtitle: c.budget > 0
                          ? Text('Budget: \$${c.budget.toStringAsFixed(2)}')
                          : null,
                      children: [
                        ...c.subcategories.map(
                          (s) => ListTile(
                            title: Text(s),
                            leading: const Icon(Icons.subdirectory_arrow_right),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
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
                                onPressed: () => _addSubcategory(c),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete Category'),
                          onPressed: () => box.deleteAt(i),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
