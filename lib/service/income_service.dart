import 'package:hive/hive.dart';
import '../models/income.dart';

class IncomeService {
  final Box<Income> _box = Hive.box<Income>('incomes');

  List<Income> getAllIncomes() => _box.values.toList();

  Income? getIncome(int index) =>
      index >= 0 && index < _box.length ? _box.getAt(index) : null;

  void addIncome(Income income) => _box.add(income);

  void updateIncome(int index, Income income) {
    if (index >= 0 && index < _box.length) {
      _box.putAt(index, income);
    }
  }

  void deleteIncome(int index) {
    if (index >= 0 && index < _box.length) {
      _box.deleteAt(index);
    }
  }

  void clearAll() => _box.clear();

  double getTotalIncome() {
    return _box.values.fold(0.0, (sum, income) => sum + income.amount);
  }

  Income? getIncomeBySource(String source) {
    try {
      return _box.values.firstWhere((i) => i.source == source);
    } catch (_) {
      return null;
    }
  }
}
