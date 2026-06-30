import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../state/transaction_store.dart';

enum ChartRangeFilter { thisMonth, lastMonth, week, month, year }

class ChartsTab extends StatefulWidget {
  const ChartsTab({Key? key}) : super(key: key);

  @override
  State<ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<ChartsTab> {
  ChartRangeFilter _selectedFilter = ChartRangeFilter.thisMonth;

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionStore>().transactions;
    final filtered = _filterTransactions(transactions, _selectedFilter);
    final trend = _buildTrendSeries(filtered);
    final incomeSpots = trend.incomeSpots;
    final expenseSpots = trend.expenseSpots;
    final labels = trend.labels;
    final maxY = _computeMaxY(incomeSpots, expenseSpots);
    final categoryTotals = _buildCategoryTotals(filtered);
    final totalIncome = filtered
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Charts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ChartRangeFilter.values.map((filter) {
                  return ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: _selectedFilter == filter,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Records',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text('${filtered.length}',
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Income',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(
                            'BDT ${totalIncome.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.green),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expense',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(
                            'BDT ${totalExpense.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Monthly Spending Trend
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income vs Expense Trend',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      filtered.isEmpty
                          ? SizedBox(
                              height: 220,
                              child: Center(
                                child: Text(
                                  transactions.isEmpty
                                      ? 'No records yet'
                                      : 'No records in selected range',
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 250,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: true),
                                  minX: 0,
                                  maxX: (labels.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: maxY,
                                  lineTouchData:
                                      const LineTouchData(enabled: true),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= labels.length) {
                                            return const SizedBox.shrink();
                                          }

                                          final step = labels.length > 8
                                              ? (labels.length / 6).ceil()
                                              : 1;
                                          if (idx % step != 0 &&
                                              idx != labels.length - 1) {
                                            return const SizedBox.shrink();
                                          }

                                          final text = labels[idx];
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(text,
                                                style: const TextStyle(
                                                    fontSize: 10)),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, _) => Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: incomeSpots,
                                      isCurved: incomeSpots.length > 2,
                                      color: Colors.green,
                                      barWidth: 3,
                                      dotData: FlDotData(
                                          show: incomeSpots.length <= 2),
                                    ),
                                    LineChartBarData(
                                      spots: expenseSpots,
                                      isCurved: expenseSpots.length > 2,
                                      color: Colors.red,
                                      barWidth: 3,
                                      dotData: FlDotData(
                                          show: expenseSpots.length <= 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          _LegendDot(color: Colors.green, text: 'Income'),
                          SizedBox(width: 16),
                          _LegendDot(color: Colors.red, text: 'Expense'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Breakdown
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Breakdown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      categoryTotals.isEmpty
                          ? const SizedBox(
                              height: 200,
                              child: Center(child: Text('No category data')),
                            )
                          : SizedBox(
                              height: 220,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 36,
                                  sections: _buildPieSections(categoryTotals),
                                ),
                              ),
                            ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: categoryTotals.entries.map((entry) {
                          return Text(
                            '${entry.key}: ${entry.value.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _filterLabel(ChartRangeFilter filter) {
    switch (filter) {
      case ChartRangeFilter.thisMonth:
        return 'This Month';
      case ChartRangeFilter.lastMonth:
        return 'Last Month';
      case ChartRangeFilter.week:
        return 'Week';
      case ChartRangeFilter.month:
        return 'Month';
      case ChartRangeFilter.year:
        return 'Year';
    }
  }

  List<Transaction> _filterTransactions(
    List<Transaction> all,
    ChartRangeFilter filter,
  ) {
    final now = DateTime.now();

    return all.where((txn) {
      final d = txn.date;
      switch (filter) {
        case ChartRangeFilter.thisMonth:
          return d.year == now.year && d.month == now.month;
        case ChartRangeFilter.lastMonth:
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          return d.year == lastMonth.year && d.month == lastMonth.month;
        case ChartRangeFilter.week:
          final start = now.subtract(const Duration(days: 7));
          return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
              !d.isAfter(now);
        case ChartRangeFilter.month:
          final start = now.subtract(const Duration(days: 30));
          return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
              !d.isAfter(now);
        case ChartRangeFilter.year:
          final start = now.subtract(const Duration(days: 365));
          return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
              !d.isAfter(now);
      }
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  _TrendSeries _buildTrendSeries(List<Transaction> txns) {
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final labels = <String>[];

    double incomeRunning = 0;
    double expenseRunning = 0;

    for (var i = 0; i < txns.length; i++) {
      final t = txns[i];
      if (t.type == TransactionType.income) {
        incomeRunning += t.amount;
      } else {
        expenseRunning += t.amount;
      }

      incomeSpots.add(FlSpot(i.toDouble(), incomeRunning));
      expenseSpots.add(FlSpot(i.toDouble(), expenseRunning));
      labels.add('${t.date.day}/${t.date.month}');
    }

    return _TrendSeries(
      incomeSpots: incomeSpots,
      expenseSpots: expenseSpots,
      labels: labels,
    );
  }

  double _computeMaxY(List<FlSpot> incomeSpots, List<FlSpot> expenseSpots) {
    final values = <double>[
      ...incomeSpots.map((e) => e.y),
      ...expenseSpots.map((e) => e.y),
    ];
    if (values.isEmpty) return 100;
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 100;
    return max * 1.2;
  }

  Map<String, double> _buildCategoryTotals(List<Transaction> txns) {
    final totals = <String, double>{};
    for (final t in txns) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> totals) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.brown,
      Colors.cyan,
    ];
    final grandTotal = totals.values.fold<double>(0, (a, b) => a + b);

    final list = totals.entries.toList();
    return List.generate(list.length, (index) {
      final entry = list[index];
      final percent = grandTotal == 0 ? 0 : (entry.value / grandTotal) * 100;
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: '${entry.key}\n${percent.toStringAsFixed(0)}%',
        radius: 58,
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
      );
    });
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

class _TrendSeries {
  final List<FlSpot> incomeSpots;
  final List<FlSpot> expenseSpots;
  final List<String> labels;

  const _TrendSeries({
    required this.incomeSpots,
    required this.expenseSpots,
    required this.labels,
  });
}
