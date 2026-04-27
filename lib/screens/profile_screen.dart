import 'package:expense_management_app/service/file_service.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final FileService _fileService = FileService();

  Future<void> _showImportModeDialog(
    BuildContext context,
    PickedImportFile file,
  ) async {
    if (!file.isJson && !file.isCsv) {
      _showMessage(context, 'Please select a JSON or CSV file', isError: true);
      return;
    }

    final mode = await showDialog<ImportMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Mode'),
        content: const Text(
          'How would you like to handle existing data?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImportMode.merge),
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImportMode.replace),
            child: const Text('Replace All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImportMode.skip),
            child: const Text('Skip Duplicates'),
          ),
        ],
      ),
    );

    if (mode == null) return;

    try {
      ImportResult result;
      if (file.isJson) {
        result = await _fileService.importFromJson(file, mode);
      } else {
        result = await _fileService.importFromCsv(file, mode);
      }

      if (context.mounted) {
        final message =
            'Imported: ${result.imported}, Updated: ${result.replaced}, Skipped: ${result.skipped}';
        if (result.errors.isNotEmpty) {
          _showMessage(
            context,
            '$message\nErrors: ${result.errors.length}',
            isError: result.imported == 0 && result.replaced == 0,
          );
        } else {
          _showMessage(context, message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Import failed: $e', isError: true);
      }
    }
  }

  Future<void> _importExpenses(BuildContext context) async {
    final file = await _fileService.pickFileForImport();
    if (file == null) return;

    if (context.mounted) {
      await _showImportModeDialog(context, file);
    }
  }

  Future<void> _exportAsJson(BuildContext context) async {
    final result = await _fileService.exportToJson();
    if (context.mounted) {
      if (result.success) {
        _showMessage(context, _exportMessage(result, 'JSON'));
      } else {
        _showMessage(context, 'Export failed', isError: true);
      }
    }
  }

  Future<void> _exportAsCsv(BuildContext context) async {
    final result = await _fileService.exportToCsv();
    if (context.mounted) {
      if (result.success) {
        _showMessage(context, _exportMessage(result, 'CSV'));
      } else {
        _showMessage(context, 'Export failed', isError: true);
      }
    }
  }

  String _exportMessage(ExportResult result, String type) {
    if (result.path == null || result.path!.isEmpty) {
      return '$type export started';
    }

    return 'Exported to:\n${result.path}';
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
              'Data Import',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: const Text('Import from File'),
              onPressed: () => _importExpenses(context),
            ),
          ],
        ),
      ),
    );
  }
}
