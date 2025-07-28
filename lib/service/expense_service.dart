import 'package:hive/hive.dart';
import '../models/expense.dart';

class ExpenseService {
  final Box<Expense> _box = Hive.box<Expense>('expenses');

  List<Expense> getAllExpenses() => _box.values.toList();

  void addExpense(Expense expense) => _box.add(expense);

  void deleteExpense(int index) => _box.deleteAt(index);
}
