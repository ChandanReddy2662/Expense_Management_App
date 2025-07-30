import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/expense.dart';
import '../models/category.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<String> _getStoragePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> _exportAsJson(BuildContext context) async {
    final expenseBox = Hive.box<Expense>('expenses');
    final categoryBox = Hive.box<Category>('categories');

    final exportData = {
      'categories': categoryBox.values.map((c) => c.toMap()).toList(),
      'expenses': expenseBox.values.map((e) => e.toMap()).toList(),
    };

    final jsonStr = jsonEncode(exportData);
    final path = await _getStoragePath();
    final file = File('$path/expense_data.json');
    await file.writeAsString(jsonStr);

    _showMessage(context, 'Exported as JSON to:\n${file.path}');
  }

  Future<void> _exportAsCsv(BuildContext context) async {
    final expenseBox = Hive.box<Expense>('expenses');
    final expenses = expenseBox.values.toList();

    final rows = [
      ['Title', 'Amount', 'Date', 'Category', 'Subcategory', 'Description']
    ];

    for (final e in expenses) {
      rows.add([
        e.title,
        e.amount.toString(),
        e.date.toIso8601String(),
        e.category,
        e.subcategory ?? '',
        e.description ?? ''
      ]);
    }

    final csvStr = const ListToCsvConverter().convert(rows);
    final path = await _getStoragePath();
    final file = File('$path/expense_data.csv');
    await file.writeAsString(csvStr);

    _showMessage(context, 'Exported as CSV to:\n${file.path}');
  }

  Future<void> _importFromJsonFile(BuildContext context) async {
    final path = await _getStoragePath();
    final file = File('$path/expense_data.json');

    if (!file.existsSync()) {
      _showMessage(context, 'JSON file not found at:\n${file.path}');
      return;
    }

    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);

      final categoryBox = Hive.box<Category>('categories');
      final expenseBox = Hive.box<Expense>('expenses');

      for (var c in decoded['categories']) {
        categoryBox.add(Category.fromMap(c));
      }
      for (var e in decoded['expenses']) {
        expenseBox.add(Expense.fromMap(e));
      }

      _showMessage(context, 'Imported data from JSON:\n${file.path}');
    } catch (e) {
      _showMessage(context, 'JSON import failed: $e');
    }
  }

  Future<void> _importFromCsvFile(BuildContext context) async {
    final path = await _getStoragePath();
    final file = File('$path/expense_data.csv');

    if (!file.existsSync()) {
      _showMessage(context, 'CSV file not found at:\n${file.path}');
      return;
    }

    try {
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);

      final expenseBox = Hive.box<Expense>('expenses');
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final expense = Expense(
          title: row[0].toString(),
          amount: double.tryParse(row[1].toString()) ?? 0,
          date: DateTime.parse(row[2].toString()),
          category: row[3].toString(),
          subcategory: row[4].toString(),
          description: row[5].toString(),
        );
        expenseBox.add(expense);
      }

      _showMessage(context, 'Imported data from CSV:\n${file.path}');
    } catch (e) {
      _showMessage(context, 'CSV import failed: $e');
    }
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, maxLines: 5, overflow: TextOverflow.ellipsis)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Data')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Data Export', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Export as JSON'),
              onPressed: () => _exportAsJson(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Export as CSV'),
              onPressed: () => _exportAsCsv(context),
            ),
            const SizedBox(height: 24),
            const Text('Data Import (place file in app folder)', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: const Text('Import JSON'),
              onPressed: () => _importFromJsonFile(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: const Text('Import CSV'),
              onPressed: () => _importFromCsvFile(context),
            ),
          ],
        ),
      ),
    );
  }
}
