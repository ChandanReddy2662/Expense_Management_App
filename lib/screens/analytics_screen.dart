import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../models/category.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = Hive.box<Expense>('expenses')
        .values
        .where((e) =>
            e.date.month == DateTime.now().month &&
            e.date.year == DateTime.now().year)
        .toList();

    final categoryMap = <String, double>{};
    for (final e in expenses) {
      categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
    }

    final pieSections = categoryMap.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: entry.key,
        color: Colors.primaries[entry.key.hashCode % Colors.primaries.length],
        radius: 60,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: expenses.isEmpty
            ? const Center(child: Text("No data to analyze"))
            : Column(
                children: [
                  const Text("Spending by Category"),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PieChart(
                      PieChartData(sections: pieSections),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
