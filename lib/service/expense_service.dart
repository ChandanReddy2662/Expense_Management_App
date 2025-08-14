import 'package:hive/hive.dart';
import '../models/expense.dart';

class ExpenseService {
  final Box<Expense> _box = Hive.box<Expense>('expenses');

  List<Expense> getAllExpenses() => _box.values.toList();

  Expense? getExpense(int index) =>
      index >= 0 && index < _box.length ? _box.getAt(index) : null;

  void addExpense(Expense expense) => _box.add(expense);

  void updateExpense(int index, Expense expense) {
    if (index >= 0 && index < _box.length) {
      _box.putAt(index, expense);
    }
  }

  void deleteExpense(int index) {
    if (index >= 0 && index < _box.length) {
      _box.deleteAt(index);
    }
  }

  void clearAll() => _box.clear();

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _box.values
        .where((e) => e.date.isAfter(start.subtract(const Duration(days: 1))) &&
                      e.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  List<Expense> getExpensesByCategory(String category) {
    return _box.values.where((e) => e.category == category).toList();
  }

  List<Expense> getExpensesByIncomeSource(String source) {
    return _box.values.where((e) => e.fromIncomeSource == source).toList();
  }
}
