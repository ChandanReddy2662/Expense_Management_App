import 'package:hive/hive.dart';
part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String category;

  @HiveField(5)
  String subcategory;

  @HiveField(6)
  String description;

  @HiveField(7)
  String? fromIncomeSource; // name of the income source

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.subcategory = '',
    this.description = '',
    this.fromIncomeSource = '',
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      category: map['category']?.toString() ?? 'General',
      subcategory: map['subcategory']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      fromIncomeSource: map['fromIncomeSource']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'fromIncomeSource': fromIncomeSource,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
