import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/category.dart' as category_model;
import '../models/expense.dart' as expense_model;
import '../models/income.dart' as income_model;

class ImportResult {
  final int imported;
  final int skipped;
  final int replaced;
  final List<String> errors;

  ImportResult({
    required this.imported,
    required this.skipped,
    required this.replaced,
    this.errors = const [],
  });

  int get total => imported + skipped + replaced;
}

class ExportResult {
  final bool success;
  final String? path;

  const ExportResult({required this.success, this.path});
}

enum ImportMode {
  merge, // Update matching items and add new items.
  replace, // Replace all existing data for the imported file type.
  skip, // Add only new items and keep existing duplicates unchanged.
}

class PickedImportFile {
  final String name;
  final String? path;
  final Uint8List? bytes;

  const PickedImportFile({required this.name, this.path, this.bytes});

  bool get isJson => name.toLowerCase().endsWith('.json');
  bool get isCsv => name.toLowerCase().endsWith('.csv');
}

class FileService {
  Future<PickedImportFile?> pickFileForImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('No file selected');
        return null;
      }

      final selected = result.files.first;
      if (selected.bytes == null) {
        debugPrint('Selected file has no readable bytes');
        return null;
      }

      debugPrint('Selected file: ${selected.name}');
      return PickedImportFile(
        name: selected.name,
        path: selected.path,
        bytes: selected.bytes,
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  Future<ImportResult> importFromJson(
    PickedImportFile file,
    ImportMode mode,
  ) async {
    try {
      final content = await _readImportFile(file);
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        return ImportResult(
          imported: 0,
          skipped: 0,
          replaced: 0,
          errors: [
            'JSON must contain an object with categories, expenses, or incomes',
          ],
        );
      }

      final data = Map<String, dynamic>.from(decoded);
      final expenseBox = Hive.box<expense_model.Expense>('expenses');
      final categoryBox = Hive.box<category_model.Category>('categories');
      final incomeBox = Hive.box<income_model.Income>('incomes');

      var imported = 0;
      var skipped = 0;
      var replaced = 0;
      final errors = <String>[];

      if (mode == ImportMode.replace) {
        await expenseBox.clear();
        await categoryBox.clear();
        await incomeBox.clear();
      }

      final categories = data['categories'];
      if (categories is List) {
        for (final value in categories) {
          try {
            if (value is! Map) {
              errors.add('Category error: invalid category row');
              continue;
            }

            final category = category_model.Category.fromMap(
              Map<String, dynamic>.from(value),
            );
            final existingIndex = _findCategoryIndex(categoryBox, category.name);

            if (mode == ImportMode.skip && existingIndex != -1) {
              skipped++;
            } else if (mode == ImportMode.merge && existingIndex != -1) {
              await categoryBox.putAt(existingIndex, category);
              replaced++;
            } else {
              await categoryBox.add(category);
              imported++;
            }
          } catch (e) {
            errors.add('Category error: $e');
          }
        }
      }

      final expenses = data['expenses'];
      if (expenses is List) {
        for (final value in expenses) {
          try {
            if (value is! Map) {
              errors.add('Expense error: invalid expense row');
              continue;
            }

            final expense = expense_model.Expense.fromMap(
              Map<String, dynamic>.from(value),
            );
            final existingIndex = _findExpenseIndex(expenseBox, expense);

            if (mode == ImportMode.skip && existingIndex != -1) {
              skipped++;
            } else if (mode == ImportMode.merge && existingIndex != -1) {
              await expenseBox.putAt(existingIndex, expense);
              replaced++;
            } else {
              await expenseBox.add(expense);
              imported++;
            }
          } catch (e) {
            errors.add('Expense error: $e');
          }
        }
      }

      final incomes = data['incomes'];
      if (incomes is List) {
        for (final value in incomes) {
          try {
            if (value is! Map) {
              errors.add('Income error: invalid income row');
              continue;
            }

            final income = income_model.Income.fromMap(
              Map<String, dynamic>.from(value),
            );
            final existingIndex = _findIncomeIndex(incomeBox, income.source);

            if (mode == ImportMode.skip && existingIndex != -1) {
              skipped++;
            } else if (mode == ImportMode.merge && existingIndex != -1) {
              await incomeBox.putAt(existingIndex, income);
              replaced++;
            } else {
              await incomeBox.add(income);
              imported++;
            }
          } catch (e) {
            errors.add('Income error: $e');
          }
        }
      }

      return ImportResult(
        imported: imported,
        skipped: skipped,
        replaced: replaced,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        imported: 0,
        skipped: 0,
        replaced: 0,
        errors: ['Failed to parse JSON: $e'],
      );
    }
  }

  Future<ImportResult> importFromCsv(
    PickedImportFile file,
    ImportMode mode,
  ) async {
    try {
      final content = await _readImportFile(file);
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) {
        return ImportResult(
          imported: 0,
          skipped: 0,
          replaced: 0,
          errors: ['CSV file is empty'],
        );
      }

      final expenseBox = Hive.box<expense_model.Expense>('expenses');
      final hasHeader = rows.first.any(
        (cell) =>
            cell.toString().toLowerCase().contains('title') ||
            cell.toString().toLowerCase().contains('amount'),
      );
      final dataRows = hasHeader ? rows.skip(1) : rows;

      var imported = 0;
      var skipped = 0;
      var replaced = 0;
      var rowIndex = 0;
      final errors = <String>[];

      if (mode == ImportMode.replace) {
        await expenseBox.clear();
      }

      for (final row in dataRows) {
        try {
          if (row.length < 4) continue;
          rowIndex++;

          final expense = expense_model.Expense(
            id: '${DateTime.now().microsecondsSinceEpoch}-$rowIndex',
            title: row[0].toString(),
            amount: double.tryParse(row[1].toString()) ?? 0.0,
            date: DateTime.tryParse(row[2].toString()) ?? DateTime.now(),
            category: row[3].toString(),
            subcategory: row.length > 4 ? row[4].toString() : '',
            description: row.length > 5 ? row[5].toString() : '',
            fromIncomeSource: row.length > 6 ? row[6].toString() : '',
          );
          final existingIndex = _findExpenseIndex(expenseBox, expense);

          if (mode == ImportMode.skip && existingIndex != -1) {
            skipped++;
          } else if (mode == ImportMode.merge && existingIndex != -1) {
            await expenseBox.putAt(existingIndex, expense);
            replaced++;
          } else {
            await expenseBox.add(expense);
            imported++;
          }
        } catch (e) {
          errors.add('Row error: $e');
        }
      }

      return ImportResult(
        imported: imported,
        skipped: skipped,
        replaced: replaced,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        imported: 0,
        skipped: 0,
        replaced: 0,
        errors: ['Failed to parse CSV: $e'],
      );
    }
  }

  Future<ExportResult> exportToJson() async {
    try {
      final expenseBox = Hive.box<expense_model.Expense>('expenses');
      final categoryBox = Hive.box<category_model.Category>('categories');
      final incomeBox = Hive.box<income_model.Income>('incomes');

      final exportData = {
        'categories': categoryBox.values.map((c) => c.toMap()).toList(),
        'expenses': expenseBox.values.map((e) => e.toMap()).toList(),
        'incomes': incomeBox.values.map((i) => i.toMap()).toList(),
      };

      return _saveExportFile(
        fileName: 'expense_data.json',
        extension: 'json',
        content: jsonEncode(exportData),
      );
    } catch (e) {
      debugPrint('JSON export error: $e');
      return const ExportResult(success: false);
    }
  }

  Future<ExportResult> exportToCsv() async {
    try {
      final expenseBox = Hive.box<expense_model.Expense>('expenses');
      final rows = <List<dynamic>>[
        [
          'Title',
          'Amount',
          'Date',
          'Category',
          'Subcategory',
          'Description',
          'FromIncomeSource',
        ],
      ];

      for (final e in expenseBox.values) {
        rows.add([
          e.title,
          e.amount.toString(),
          e.date.toIso8601String(),
          e.category,
          e.subcategory,
          e.description,
          e.fromIncomeSource ?? '',
        ]);
      }

      return _saveExportFile(
        fileName: 'expense_data.csv',
        extension: 'csv',
        content: const ListToCsvConverter().convert(rows),
      );
    } catch (e) {
      debugPrint('CSV export error: $e');
      return const ExportResult(success: false);
    }
  }

  int _findExpenseIndex(
    Box<expense_model.Expense> box,
    expense_model.Expense expense,
  ) {
    for (var i = 0; i < box.length; i++) {
      final existing = box.getAt(i);
      if (existing == null) continue;

      final sameId = expense.id.isNotEmpty && existing.id == expense.id;
      final sameTransaction =
          existing.title == expense.title &&
          existing.amount == expense.amount &&
          existing.category == expense.category &&
          existing.subcategory == expense.subcategory &&
          existing.date.year == expense.date.year &&
          existing.date.month == expense.date.month &&
          existing.date.day == expense.date.day;

      if (sameId || sameTransaction) {
        return i;
      }
    }
    return -1;
  }

  int _findCategoryIndex(Box<category_model.Category> box, String name) {
    for (var i = 0; i < box.length; i++) {
      final existing = box.getAt(i);
      if (existing != null &&
          existing.name.toLowerCase() == name.toLowerCase()) {
        return i;
      }
    }
    return -1;
  }

  int _findIncomeIndex(Box<income_model.Income> box, String source) {
    for (var i = 0; i < box.length; i++) {
      final existing = box.getAt(i);
      if (existing != null &&
          existing.source.toLowerCase() == source.toLowerCase()) {
        return i;
      }
    }
    return -1;
  }

  Future<String> _readImportFile(PickedImportFile file) async {
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }

    throw UnsupportedError('Selected file could not be read');
  }

  Future<ExportResult> _saveExportFile({
    required String fileName,
    required String extension,
    required String content,
  }) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension],
        bytes: Uint8List.fromList(utf8.encode(content)),
      );

      return ExportResult(success: kIsWeb || path != null, path: path);
    } catch (e) {
      debugPrint('Error saving $fileName: $e');
      return const ExportResult(success: false);
    }
  }
}
