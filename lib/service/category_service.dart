import 'package:hive/hive.dart';
import '../models/category.dart';

class CategoryService {
  final Box<Category> _box = Hive.box<Category>('categories');

  List<Category> getAllCategories() => _box.values.toList();

  Category? getCategory(int index) =>
      index >= 0 && index < _box.length ? _box.getAt(index) : null;

  void addCategory(Category category) => _box.add(category);

  void updateCategory(int index, Category category) {
    if (index >= 0 && index < _box.length) {
      _box.putAt(index, category);
    }
  }

  void deleteCategory(int index) {
    if (index >= 0 && index < _box.length) {
      _box.deleteAt(index);
    }
  }

  void clearAll() => _box.clear();

  Category? getCategoryByName(String name) {
    try {
      return _box.values.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  List<String> getSubcategories(String category){
    try{
      return _box.values.firstWhere((c) => c.name == category).subcategories;
    }
    catch(_){
      
      return [];
    }
  }
}
