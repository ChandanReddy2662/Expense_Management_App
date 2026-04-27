import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int iconCode;

  @HiveField(2)
  final double budget;

  @HiveField(3)
  final List<String> subcategories;

  Category({
    required this.name,
    required this.iconCode,
    this.budget = 0.0,
    this.subcategories = const [],
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      name: map['name']?.toString() ?? 'General',
      iconCode: _toInt(map['iconCode']),
      budget: _toDouble(map['budget']),
      subcategories: (map['subcategories'] as List? ?? [])
          .map((value) => value.toString())
          .toList(),
    );
  }

  // 👇 Optional: for exporting
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCode': iconCode,
      'budget': budget,
      'subcategories': subcategories,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? Icons.category.codePoint;
  }
}

// extension CategoryMapper on Category {
//   Map<String, dynamic> toMap() => {
//         'name': name,
//         'iconCode': iconCode,
//         'budget': budget,
//         'subcategories': subcategories,
//       };

//   static Category fromMap(Map<String, dynamic> map) => Category(
//         name: map['name'],
//         iconCode: map['iconCode'],
//         budget: map['budget'],
//         subcategories: List<String>.from(map['subcategories'] ?? []),
//       );
// }
