import 'package:flutter/foundation.dart';
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
    if (kDebugMode) {
      print("$map  ${map['source']} ${map['amount']} ${map['isDefault']}");
    }
    return Income(
      source: map['source'],
      amount: map['amount'],
      isDefault: map['isDefault'],
    );
  }

  // 👇 Optional: for exporting
  Map<String, dynamic> toMap() {
    return {'source': source, 'amount': amount, 'isDefault': isDefault};
  }
}
