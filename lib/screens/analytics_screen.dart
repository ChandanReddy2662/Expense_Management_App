import 'dart:collection';

import 'package:expense_management_app/models/income.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTimeRange? _dateRange;
  bool _viewSubcategories = false;
  bool _barView = false;

  List<Expense> getFilteredExpenses() {
    final allExpenses = Hive.box<Expense>('expenses').values.toList();
    
    return allExpenses.where((e) {
      final date = e.date;
      if (_dateRange == null) {
        final now = DateTime.now();
        return date.month == now.month && date.year == now.year;
      } else {
        return date.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }
    }).toList();
  }

  Map<String, double> computeTotals(List<Expense> expenses) {
    final map = <String, double>{};

    for (final e in expenses) {
      final key = _viewSubcategories
          ? '${e.category} > ${e.subcategory ?? "Other"}'
          : e.category;

      map[key] = (map[key] ?? 0) + e.amount;
    }

    return map;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _dateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0),
          ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }
 
  @override
  Widget build(BuildContext context) {  
    final expenses = getFilteredExpenses();
    final totals = computeTotals(expenses);
    final totalAmount = totals.values.fold(0.0, (sum, val) => sum + val);

    final pieSections = totals.entries.map((entry) {
      final color =
          Colors.primaries[entry.key.hashCode % Colors.primaries.length];

      return PieChartSectionData(
        value: entry.value,
        title: entry.key.split('>').last.trim(),
        color: color,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    final barSpots = totals.entries.toList();
    barSpots.sort((a, b) => b.value.compareTo(a.value)); // Sort descending

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: Icon(
              _viewSubcategories ? Icons.view_module : Icons.view_list,
            ),
            tooltip: _viewSubcategories
                ? 'View by Category'
                : 'View by Subcategory',
            onPressed: () =>
                setState(() => _viewSubcategories = !_viewSubcategories),
          ),
          IconButton(
            icon: Icon(_barView ? Icons.pie_chart : Icons.bar_chart),
            tooltip: _barView ? 'Show Pie Chart' : 'Show Bar Chart',
            onPressed: () => setState(() => _barView = !_barView),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: expenses.isEmpty
            ? const Center(child: Text("No data to analyze"))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Spending: ₹${totalAmount.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _viewSubcategories
                        ? "Spending by Subcategory"
                        : "Spending by Category",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),

                  /// CHART SWITCH: PIE OR BAR
                  if (!_barView)
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: pieSections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: totalAmount / 5,
                                reservedSize: 40,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < barSpots.length) {
                                    final label = barSpots[index].key;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        label.length > 8
                                            ? '${label.substring(0, 6)}...'
                                            : label,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            topTitles: AxisTitles(),
                            rightTitles: AxisTitles(),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: true),
                          barGroups: List.generate(barSpots.length, (index) {
                            final e = barSpots[index];
                            final color =
                                Colors.primaries[e.key.hashCode %
                                    Colors.primaries.length];
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value,
                                  width: 18,
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    "Breakdown",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: totals.entries.map((entry) {
                        final color =
                            Colors.primaries[entry.key.hashCode %
                                Colors.primaries.length];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: color),
                          title: Text(entry.key),
                          trailing: Text("₹${entry.value.toStringAsFixed(2)}"),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
