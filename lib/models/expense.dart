import 'package:hive/hive.dart';
part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String category;

  @HiveField(4)
  String subcategory;

  @HiveField(5)
  String description;

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.subcategory = '',
    this.description = '',
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      title: map['title'],
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      category: map['category'],
      subcategory: map['subcategory'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'subcategory': subcategory,
      'description': description,
    };
  }
}

// extension ExpenseMapper on Expense {
//   Map<String, dynamic> toMap() => {
//         'title': title,
//         'amount': amount,
//         'date': date.toIso8601String(),
//         'category': category,
//         'subcategory': subcategory,
//         'description': description,
//       };

//   static Expense fromMap(Map<String, dynamic> map) => Expense(
//         title: map['title'],
//         amount: map['amount'],
//         date: DateTime.parse(map['date']),
//         category: map['category'],
//         subcategory: map['subcategory'],
//         description: map['description'],
//       );
// }
