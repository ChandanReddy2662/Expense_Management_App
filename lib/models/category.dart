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
    this.budget = 0,
    this.subcategories = const [],
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
}
