import 'dart:convert';
import 'dart:io';
import 'package:expense_management_app/models/income.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import '../models/category.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<String> _getStoragePath() async {
    if (kIsWeb) return 'assets';
    final dir = await getDownloadsDirectory();

    if (dir != null) {
      return dir.path;
    } else {
      return '/storage/emulated/0/Downloads';
    }
  }

  Future<void> _exportAsJson(BuildContext context) async {
    final expenseBox = Hive.box<Expense>('expenses');
    final categoryBox = Hive.box<Category>('categories');
    final incomBox = Hive.box<Income>('incomes');

    final exportData = {
      'categories': categoryBox.values.map((c) => c.toMap()).toList(),
      'expenses': expenseBox.values.map((e) => e.toMap()).toList(),
      'incomes': incomBox.values.map((e) => e.toMap()).toList(),
    };

    final jsonStr = jsonEncode(exportData);
    final path = await _getStoragePath();
    final file = File('$path/expense_data.json');
    await file.writeAsString(jsonStr);

    // ignore: use_build_context_synchronously
    _showMessage(context, 'Exported as JSON to:\n${file.path}');
  }

  Future<void> _exportAsCsv(BuildContext context) async {
    final expenseBox = Hive.box<Expense>('expenses');
    final expenses = expenseBox.values.toList();

    final rows = [
      ['Title', 'Amount', 'Date', 'Category', 'Subcategory', 'Description'],
    ];

    for (final e in expenses) {
      rows.add([
        e.title,
        e.amount.toString(),
        e.date.toIso8601String(),
        e.category,
        e.subcategory ?? '',
        e.description ?? '',
        e.fromIncomeSource ?? '',
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

    if (!kIsWeb && !file.existsSync()) {
      _showMessage(context, 'JSON file not found at:\n${file.path}');
      return;
    }

    try {
      final content = kIsWeb
          ? await rootBundle.loadString('$path/expense_data.json')
          : await file.readAsString();
      final decoded = jsonDecode(content);

      final categoryBox = Hive.box<Category>('categories');
      final expenseBox = Hive.box<Expense>('expenses');
      final incomeBox = Hive.box<Income>('incomes');
      // print(decoded);

      await categoryBox.clear();
      await expenseBox.clear();
      await incomeBox.clear();

      for (var c in decoded['categories']) {
        categoryBox.add(Category.fromMap(c));
      }
      for (var e in decoded['expenses']) {
        expenseBox.add(Expense.fromMap(e));
      }
      print(decoded['incomes']);
      for (var i in decoded['incomes']) {
        incomeBox.add(Income.fromMap(i));
      }
      _showMessage(context, 'Imported data from JSON:\n${file.path}');
    } catch (e) {
      _showMessage(context, 'JSON import failed: $e');
    }
  }

  void _showMessage(BuildContext context, String msg, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = isError
        ? Colors.redAccent
        : colorScheme.primaryContainer;

    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isError ? Colors.white : colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: isError
                      ? Colors.white
                      : colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
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
            SizedBox(height: 8,),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Export as CSV'),
              onPressed: () => _exportAsCsv(context),
            ),
            const SizedBox(height: 24),
            const Text(
              'Data Import (place file in app folder)',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: const Text('Import JSON'),
              onPressed: () => _importFromJsonFile(context),
            ),
          ],
        ),
      ),
    );
  }
}
