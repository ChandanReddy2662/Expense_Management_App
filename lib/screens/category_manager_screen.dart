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
  IconData _selectedIcon = Icons.category;

  void _addCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final newCategory = Category(
      name: name,
      iconCode: _selectedIcon.codePoint,
    );

    Hive.box<Category>('categories').add(newCategory);
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Category>('categories');
    final iconChoices = [
      Icons.fastfood,
      Icons.flight,
      Icons.shopping_bag,
      Icons.receipt,
      Icons.category,
      Icons.home,
      Icons.pets,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Column(
        children: [
          ListTile(
            title: TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            trailing: DropdownButton<IconData>(
              value: _selectedIcon,
              items: iconChoices.map((icon) {
                return DropdownMenuItem(
                  value: icon,
                  child: Icon(icon),
                );
              }).toList(),
              onChanged: (icon) {
                if (icon != null) {
                  setState(() {
                    _selectedIcon = icon;
                  });
                }
              },
            ),
          ),
          ElevatedButton(
            onPressed: _addCategory,
            child: const Text('Add Category'),
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<Category> box, _) {
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final category = box.getAt(index)!;
                    return ListTile(
                      leading: Icon(category.icon),
                      title: Text(category.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => box.deleteAt(index),
                      ),
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
