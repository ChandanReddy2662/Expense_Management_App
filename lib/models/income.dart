import 'package:hive/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 3) // make sure typeId is unique
class Income extends HiveObject {
  @HiveField(0)
  String source;

  @HiveField(1)
  double amount;

  @HiveField(2)
  bool isDefault;

  Income({required this.source, required this.amount, this.isDefault = false});

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      source: map['source']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      isDefault: map['isDefault'] == true,
    );
  }

  // 👇 Optional: for exporting
  Map<String, dynamic> toMap() {
    return {'source': source, 'amount': amount, 'isDefault': isDefault};
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
