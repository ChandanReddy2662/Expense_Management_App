import 'package:hive/hive.dart';

part 'frequent_expense.g.dart';

@HiveType(typeId: 4)
class FrequentExpense extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String category;

  @HiveField(4)
  String subcategory;

  @HiveField(5)
  String description;

  @HiveField(6)
  String? fromIncomeSource;

  FrequentExpense({
    required this.name,
    required this.title,
    required this.amount,
    required this.category,
    this.subcategory = '',
    this.description = '',
    this.fromIncomeSource = '',
  });
}
