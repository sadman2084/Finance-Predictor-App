import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'dart:math';

import '../models/transaction_model.dart';
import '../state/transaction_store.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  static const MethodChannel _downloadsChannel =
      MethodChannel('com.company.financepredictor/downloads');
  double _targetSavingsRate = 20;
  bool _markScenarioBest = false;
  List<Map<String, dynamic>>? _forecastCache;
  DateTime? _forecastCacheAt;
  final TextEditingController _whatIfController = TextEditingController(
    text: 'What happens if I reduce transport by 20% this month?',
  );

  @override
  void dispose() {
    _whatIfController.dispose();
    super.dispose();
  }

  static String get _apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://localhost:8000';
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionStore>().transactions;

    // Calculate totals
    double totalIncome = 0;
    double totalSpent = 0;

    for (var txn in transactions) {
      if (txn.type == TransactionType.income) {
        totalIncome += txn.amount;
      } else {
        totalSpent += txn.amount;
      }
    }

    double saved = totalIncome - totalSpent;
    final recommendations =
        _generateRecommendations(transactions, totalIncome, totalSpent, saved);
    final copilotPlan =
        _buildSmartBudgetCopilot(transactions, _targetSavingsRate);
    final healthScore = _calculateFinancialHealth(transactions);
    final overspendingWarning =
        _buildOverspendingWarning(transactions, copilotPlan);
    final whatIfResult = _simulateWhatIf(transactions, _whatIfController.text);
    final midMonthStatusColor =
        copilotPlan.isAtRisk ? Colors.red : Colors.green;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Summary Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Income',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '৳${totalIncome.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: Colors.green),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Spent',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '৳${totalSpent.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: Colors.red),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '৳${saved.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: saved >= 0
                                            ? Colors.blue
                                            : Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Risk Alert
              Card(
                color: saved >= 0 ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        saved >= 0 ? Icons.check_circle : Icons.warning,
                        color: saved >= 0 ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              saved >= 0 ? 'Good Balance' : 'Over Budget',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: saved >= 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                            Text(
                              saved >= 0
                                  ? 'You have ৳${saved.toStringAsFixed(0)} balance remaining.'
                                  : 'You have exceeded budget by ৳${(-saved).toStringAsFixed(0)}.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Spending Summary
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Transactions',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${transactions.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: Colors.blue),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${transactions.where((t) => t.type == TransactionType.income).length} income • ${transactions.where((t) => t.type == TransactionType.expense).length} expenses',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.blue[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Smart Budget Copilot
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Budget Copilot',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Target Savings: ${_targetSavingsRate.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        value: _targetSavingsRate,
                        min: 5,
                        max: 40,
                        divisions: 35,
                        label: '${_targetSavingsRate.toStringAsFixed(0)}%',
                        onChanged: (value) {
                          setState(() {
                            _targetSavingsRate = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto Monthly Expense Budget: ৳${copilotPlan.targetExpenseBudget.toStringAsFixed(0)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Projected Month-End Spend: ৳${copilotPlan.projectedMonthEndExpense.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Safe Daily Spend for remaining days: ৳${copilotPlan.safeDailySpend.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: midMonthStatusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: midMonthStatusColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          copilotPlan.isAtRisk
                              ? 'Mid-month alert: spending pace is above plan by ৳${copilotPlan.paceGap.abs().toStringAsFixed(0)}'
                              : 'On track: spending pace is within plan.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: midMonthStatusColor.shade700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _expenseComparisonText(transactions),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.blueGrey[700]),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final monthKey =
                                '${now.year}-${now.month.toString().padLeft(2, '0')}';
                            await context
                                .read<TransactionStore>()
                                .saveBudgetPlan(
                                  monthKey: monthKey,
                                  targetSavingsRate: _targetSavingsRate,
                                  targetExpenseBudget:
                                      copilotPlan.targetExpenseBudget,
                                  projectedExpense:
                                      copilotPlan.projectedMonthEndExpense,
                                  safeDailySpend: copilotPlan.safeDailySpend,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Monthly budget plan saved.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save Plan'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Category Budget Plan',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...copilotPlan.categoryPlans
                          .take(4)
                          .map(
                            (plan) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.category,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  Text(
                                    'Spent ৳${plan.currentSpent.toStringAsFixed(0)} / Budget ৳${plan.recommendedBudget.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.blueGrey[700]),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 12),
                      Text(
                        'Cut Suggestions to Hit Target',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...(copilotPlan.cutSuggestions.isEmpty
                          ? [
                              Text(
                                'No category cuts needed right now. You are on track for your savings target.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.green[700]),
                              ),
                            ]
                          : copilotPlan.cutSuggestions
                              .map(
                                (item) => _buildRecommendation(
                                  context,
                                  '✂️',
                                  'Reduce ${item.category} by ৳${item.recommendedCut.toStringAsFixed(0)}',
                                ),
                              )
                              .toList()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Financial Health Score
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Health Score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: healthScore.score >= 70
                                  ? Colors.green[50]
                                  : healthScore.score >= 45
                                      ? Colors.orange[50]
                                      : Colors.red[50],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: healthScore.score >= 70
                                    ? Colors.green
                                    : healthScore.score >= 45
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                healthScore.score.toStringAsFixed(0),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  healthScore.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final now = DateTime.now();
                                      final weekKey =
                                          '${now.year}-W${((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor() + 1}';
                                      await context
                                          .read<TransactionStore>()
                                          .saveHealthSnapshot(
                                            weekKey: weekKey,
                                            score: healthScore.score,
                                            savingsRateScore:
                                                healthScore.savingsRateScore,
                                            stabilityScore: healthScore
                                                .cashflowStabilityScore,
                                            concentrationScore: healthScore
                                                .categoryConcentrationScore,
                                            runwayScore:
                                                healthScore.runwayScore,
                                          );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Health score snapshot saved.'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.timeline),
                                    label: const Text('Save Snapshot'),
                                  ),
                                ),
                                Text(
                                  'Savings ${healthScore.savingsRateScore.toStringAsFixed(0)} • Stability ${healthScore.cashflowStabilityScore.toStringAsFixed(0)} • Diversity ${healthScore.categoryConcentrationScore.toStringAsFixed(0)} • Runway ${healthScore.runwayScore.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Weekly Trend',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 70,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: healthScore.weeklyTrend
                              .map(
                                (point) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    child: Tooltip(
                                      message:
                                          '${point.label}: ${point.score.toStringAsFixed(0)}',
                                      child: Container(
                                        height: max(8, point.score * 0.62),
                                        decoration: BoxDecoration(
                                          color: Colors.cyan[600],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Overspending Early Warning
              Card(
                elevation: 2,
                color: overspendingWarning.isWarning
                    ? Colors.orange[50]
                    : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overspending Early Warning',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        overspendingWarning.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      ...overspendingWarning.fixes
                          .map(
                              (fix) => _buildRecommendation(context, '⚠️', fix))
                          .toList(),
                      if (overspendingWarning.isWarning)
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await context
                                  .read<TransactionStore>()
                                  .saveOverspendingAlert(
                                    alertMessage: overspendingWarning.message,
                                    daysToCross:
                                        overspendingWarning.daysToCross,
                                    fixes: overspendingWarning.fixes,
                                  );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Overspending alert saved.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Save Alert'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Expense Forecast (LightGBM)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Next Month Forecast (AI Prediction)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchForecast(transactions),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 100,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError || snapshot.data == null) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Unable to load forecast',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }

                          final forecasts = snapshot.data!;
                          final totalForecastExpense = forecasts.fold<double>(
                            0,
                            (sum, item) =>
                                sum +
                                (double.tryParse(
                                        item['predicted_expense'].toString()) ??
                                    0),
                          );
                          final explanation = _buildForecastExplanation(
                            transactions,
                            forecasts,
                          );
                          return Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      forecasts.isEmpty
                                          ? 'No forecast available yet'
                                          : 'Estimated next month expense',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.blueGrey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      forecasts.isEmpty
                                          ? 'Add more expense records to generate a personalized forecast.'
                                          : '৳${totalForecastExpense.toStringAsFixed(0)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.blue[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...forecasts
                                  .map((f) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              f['period'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '৳${f['predicted_expense']}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blue[700],
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Text(
                                  '💡 This forecast is based on your recorded transactions, so the next-month amount reflects your own expense history.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.green[700]),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber[200]!),
                                ),
                                child: Text(
                                  'Why this forecast: $explanation',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.brown[700]),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // What-if Simulator
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What-if Simulator',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Examples:\n• "What if I reduce transport by 20%?"\n• "What if I earn 5000 more from part-time?"\n• "What if I buy a phone for 25000?"',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.blueGrey[700]),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _whatIfController,
                        minLines: 1,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Type a what-if scenario...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              whatIfResult.summary,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Projected Savings: ৳${whatIfResult.projectedSavings.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'End-of-Month Cash Position: ৳${whatIfResult.endOfMonthCash.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Risk Score: ${whatIfResult.riskScore.toStringAsFixed(2)} (${whatIfResult.riskLevel})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _markScenarioBest,
                        onChanged: (value) {
                          setState(() {
                            _markScenarioBest = value ?? false;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mark this scenario as best plan'),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final parsedPercent =
                                _extractPercent(_whatIfController.text) ?? 10;
                            final now = DateTime.now();
                            final monthTxns = transactions
                                .where((t) =>
                                    t.type == TransactionType.expense &&
                                    t.date.year == now.year &&
                                    t.date.month == now.month)
                                .toList();
                            final fallbackExpenseTxns = transactions
                                .where((t) => t.type == TransactionType.expense)
                                .toList();
                            final category = _extractCategory(
                              _whatIfController.text,
                              monthTxns.isEmpty
                                  ? fallbackExpenseTxns
                                  : monthTxns,
                            );

                            await context
                                .read<TransactionStore>()
                                .saveWhatIfScenario(
                                  scenario: _whatIfController.text,
                                  category: category,
                                  reductionPercent: parsedPercent,
                                  projectedSavings:
                                      whatIfResult.projectedSavings,
                                  endOfMonthCash: whatIfResult.endOfMonthCash,
                                  riskScore: whatIfResult.riskScore,
                                  isBestPlan: _markScenarioBest,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('What-if scenario saved.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bookmark_add),
                          label: const Text('Save Scenario'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recommendations
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendations',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...recommendations
                          .map((text) =>
                              _buildRecommendation(context, '💡', text))
                          .toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Comprehensive report generator
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comprehensive Report Generator',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to generate a structured report with objective, data source, methodology, insights, interpretation, and export-ready CSV.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.blueGrey[700]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                await _showComprehensiveReportDialog(
                                  context,
                                  transactions: transactions,
                                  totalIncome: totalIncome,
                                  totalSpent: totalSpent,
                                  saved: saved,
                                  copilotPlan: copilotPlan,
                                  healthScore: healthScore,
                                  warning: overspendingWarning,
                                  whatIfResult: whatIfResult,
                                );
                              },
                              icon: const Icon(Icons.summarize),
                              label:
                                  const Text('Generate Comprehensive Report'),
                            ),
                          ),
                        ],
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

  Future<void> _showComprehensiveReportDialog(
    BuildContext context, {
    required List<Transaction> transactions,
    required double totalIncome,
    required double totalSpent,
    required double saved,
    required _SmartBudgetCopilotPlan copilotPlan,
    required _FinancialHealthResult healthScore,
    required _OverspendingWarning warning,
    required _WhatIfResult whatIfResult,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    _GeneratedReportPayload? payload;
    try {
      payload = await _buildComprehensiveReport(
        transactions: transactions,
        totalIncome: totalIncome,
        totalSpent: totalSpent,
        saved: saved,
        copilotPlan: copilotPlan,
        healthScore: healthScore,
        warning: warning,
        whatIfResult: whatIfResult,
      );
    } catch (_) {
      payload = null;
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Export Comprehensive Report'),
          content: SizedBox(
            width: 720,
            child: payload == null
                ? const Text('Could not prepare export options right now.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose the format you want to export.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: payload!.narrative),
                              );
                              if (!dialogContext.mounted) return;
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Report text copied.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Report Text'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: payload!.csv),
                              );
                              if (!dialogContext.mounted) return;
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('CSV copied.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Copy CSV'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await _downloadReportPdf(dialogContext, payload!);
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download PDF'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<_GeneratedReportPayload> _buildComprehensiveReport({
    required List<Transaction> transactions,
    required double totalIncome,
    required double totalSpent,
    required double saved,
    required _SmartBudgetCopilotPlan copilotPlan,
    required _FinancialHealthResult healthScore,
    required _OverspendingWarning warning,
    required _WhatIfResult whatIfResult,
  }) async {
    final now = DateTime.now();
    final expenseByCategory = _monthlyExpenseByCategory(transactions);
    final sortedCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final savingsRate = totalIncome > 0 ? (saved / totalIncome) * 100 : 0.0;
    final weeklyTrend = _lastWeeklyNetCashflows(transactions, 6);
    final forecastRows = await _fetchForecast(transactions);

    final topCategoryText = sortedCategories.isEmpty
        ? 'No expense categories found this month.'
        : sortedCategories
            .take(5)
            .map((e) => '• ${e.key}: ${_fmtMoney(e.value)}')
            .join('\n');

    final forecastSummary = forecastRows.isEmpty
        ? 'Forecast unavailable from backend right now.'
        : forecastRows
            .map((f) => '• ${f['period']} : ${f['predicted_expense']}')
            .join('\n');

    final topCategoryPoints = sortedCategories.take(5).toList();

    final report = StringBuffer()
      ..writeln('Title and Basic Information')
      ..writeln('--------------------------------')
      ..writeln('Finance Predictor - Comprehensive Financial Report')
      ..writeln('Report engine: v2026.04.18-r3')
      ..writeln('Generated at: ${now.toIso8601String()}')
      ..writeln(
          'Reporting period: ${now.year}-${now.month.toString().padLeft(2, '0')}')
      ..writeln('Total transactions: ${transactions.length}')
      ..writeln('')
      ..writeln('Objective')
      ..writeln('--------')
      ..writeln(
          'Track monthly financial performance, detect overspending risk early, forecast next-month expenses, and recommend practical cost optimizations.')
      ..writeln('')
      ..writeln('Data Sources')
      ..writeln('------------')
      ..writeln(
          'Input source: user-entered transactions and saved planning snapshots')
      ..writeln(
          'Collections used: users/{uid}/transactions, monthly_plans, what_if_history, health_scores, alerts, category_insights')
      ..writeln(
          'Inputs used: income, expense, category, date, target savings rate, scenario text, and weekly trend windows')
      ..writeln('')
      ..writeln('Methodology')
      ..writeln('-----------')
      ..writeln(
          '- Monthly summary: income minus expense arithmetic and savings-rate computation')
      ..writeln(
          '- Category spend analysis: group by category and sort descending for top spending areas')
      ..writeln(
          '- Budget versus actual: compare target expense budget with projected month-end spend')
      ..writeln(
          '- Financial health: weighted score from savings, stability, concentration, and runway')
      ..writeln(
          '- Overspending warning: compare current spend pace with remaining budget and estimate days to breach')
      ..writeln('- Forecast: backend expense prediction with trend explanation')
      ..writeln(
          '- What-if simulation: category reduction impact on projected monthly expense and risk score')
      ..writeln(
          '- Weekly trend: rolling net cash flow for the last several weeks')
      ..writeln('')
      ..writeln('Results Overview')
      ..writeln('----------------')
      ..writeln('Monthly expense summary')
      ..writeln('• Income: ${_fmtMoney(totalIncome)}')
      ..writeln('• Expense: ${_fmtMoney(totalSpent)}')
      ..writeln('• Net savings: ${_fmtMoney(saved)}')
      ..writeln('• Savings rate: ${savingsRate.toStringAsFixed(1)}%')
      ..writeln('')
      ..writeln('Category-wise spending')
      ..writeln(topCategoryText)
      ..writeln('')
      ..writeln('Budget versus actual')
      ..writeln(
          '• Target budget: ${_fmtMoney(copilotPlan.targetExpenseBudget)}')
      ..writeln(
          '• Projected spend: ${_fmtMoney(copilotPlan.projectedMonthEndExpense)}')
      ..writeln('• Pace gap: ${_fmtMoney(copilotPlan.paceGap)}')
      ..writeln(copilotPlan.isAtRisk
          ? '• Status: At risk of budget breach'
          : '• Status: On track')
      ..writeln('')
      ..writeln('Financial health')
      ..writeln(
          '• Score: ${healthScore.score.toStringAsFixed(0)} (${healthScore.label})')
      ..writeln(
          '• Savings score: ${healthScore.savingsRateScore.toStringAsFixed(0)}')
      ..writeln(
          '• Stability score: ${healthScore.cashflowStabilityScore.toStringAsFixed(0)}')
      ..writeln(
          '• Diversity score: ${healthScore.categoryConcentrationScore.toStringAsFixed(0)}')
      ..writeln('• Runway score: ${healthScore.runwayScore.toStringAsFixed(0)}')
      ..writeln('')
      ..writeln('Overspending warning')
      ..writeln('• ${warning.message}')
      ..writeln('• Days to cross: ${warning.daysToCross?.toString() ?? 'N/A'}')
      ..writeln('• Suggested fixes:')
      ..writeln(warning.fixes.map((fix) => '  - $fix').join('\n'))
      ..writeln('')
      ..writeln('Forecast')
      ..writeln('• $forecastSummary')
      ..writeln('')
      ..writeln('What-if scenario')
      ..writeln('• ${whatIfResult.summary}')
      ..writeln(
          '• Projected savings: ${_fmtMoney(whatIfResult.projectedSavings)}')
      ..writeln(
          '• Risk: ${whatIfResult.riskScore.toStringAsFixed(2)} (${whatIfResult.riskLevel})')
      ..writeln('')
      ..writeln('Weekly trend')
      ..writeln(weeklyTrend
          .asMap()
          .entries
          .map((e) => '• Week ${e.key + 1}: ${_fmtMoney(e.value)}')
          .join('\n'))
      ..writeln('')
      ..writeln('Saved history')
      ..writeln('--------------')
      ..writeln(
          'Saved histories are maintained in Firestore collections for plans, scenarios, health snapshots, alerts, and category insights.')
      ..writeln('')
      ..writeln('Visualizations')
      ..writeln('--------------')
      ..writeln(
          'This PDF includes a category spending bar plot and a weekly net cashflow trend chart.')
      ..writeln(
          'How to read: longer bars mean higher values. Positive weekly bars mean surplus, and negative bars mean deficit.')
      ..writeln('')
      ..writeln('Interpretation')
      ..writeln('--------------')
      ..writeln(
          'This report describes the current financial position, the risk of overspending, and the practical steps that can improve monthly savings while maintaining spending control.');

    final csv = StringBuffer()
      ..writeln('section,metric,value')
      ..writeln('summary,total_income,${totalIncome.toStringAsFixed(2)}')
      ..writeln('summary,total_expense,${totalSpent.toStringAsFixed(2)}')
      ..writeln('summary,net_savings,${saved.toStringAsFixed(2)}')
      ..writeln('summary,savings_rate,${savingsRate.toStringAsFixed(2)}')
      ..writeln(
          'budget,target_expense_budget,${copilotPlan.targetExpenseBudget.toStringAsFixed(2)}')
      ..writeln(
          'budget,projected_month_end_expense,${copilotPlan.projectedMonthEndExpense.toStringAsFixed(2)}')
      ..writeln(
          'health,financial_health_score,${healthScore.score.toStringAsFixed(2)}')
      ..writeln('health,label,"${healthScore.label}"')
      ..writeln('warning,is_warning,${warning.isWarning}')
      ..writeln('warning,days_to_cross,${warning.daysToCross ?? ''}')
      ..writeln(
          'what_if,projected_savings,${whatIfResult.projectedSavings.toStringAsFixed(2)}')
      ..writeln(
          'what_if,risk_score,${whatIfResult.riskScore.toStringAsFixed(2)}');

    for (final entry in sortedCategories) {
      csv.writeln(
        'category_spend,"${entry.key.replaceAll('"', '""')}",${entry.value.toStringAsFixed(2)}',
      );
    }

    return _GeneratedReportPayload(
      narrative: report.toString(),
      csv: csv.toString(),
      topCategoryPoints: topCategoryPoints,
      weeklyTrendValues: weeklyTrend,
    );
  }

  Map<String, double> _monthlyExpenseByCategory(
      List<Transaction> transactions) {
    final now = DateTime.now();
    final totals = <String, double>{};
    for (final txn in transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month)) {
      totals[txn.category] = (totals[txn.category] ?? 0) + txn.amount;
    }
    return totals;
  }

  String _fmtMoney(double amount) => '৳${amount.toStringAsFixed(0)}';

  Future<void> _downloadReportPdf(
    BuildContext context,
    _GeneratedReportPayload payload,
  ) async {
    final doc = pw.Document();
    final lines = payload.narrative.split('\n');
    final regularFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    const headingLines = <String>{
      'Title and Basic Information',
      'Objective',
      'Data Sources',
      'Methodology',
      'Results Overview',
      'Saved history',
      'Visualizations',
      'Interpretation',
      'Monthly expense summary',
      'Category-wise spending',
      'Budget versus actual',
      'Financial health',
      'Overspending warning',
      'Forecast',
      'What-if scenario',
      'Weekly trend',
    };
    const subHeadingLines = <String>{
      'Finance Predictor - Comprehensive Financial Report',
    };

    String safePdfText(String text) {
      return text
          .replaceAll('•', '-')
          .replaceAll('×', 'x')
          .replaceAll('৳', 'BDT ');
    }

    final maxCategory = payload.topCategoryPoints.isEmpty
        ? 1.0
        : payload.topCategoryPoints
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b);
    final maxWeeklyAbs = payload.weeklyTrendValues.isEmpty
        ? 1.0
        : payload.weeklyTrendValues
            .map((v) => v.abs())
            .reduce((a, b) => a > b ? a : b);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pdfContext) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(width: 1.2, color: PdfColors.blueGrey300),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Finance Predictor',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Comprehensive Financial Report',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.blueGrey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          ...lines.map((line) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) {
              return pw.SizedBox(height: 8);
            }

            final safeLine = safePdfText(line);

            final isHeading = headingLines.contains(trimmed);
            final isSubHeading = subHeadingLines.contains(trimmed);
            final isBullet = safeLine.trim().startsWith('-');

            return pw.Padding(
              padding: pw.EdgeInsets.only(bottom: isBullet ? 2 : 5),
              child: pw.Text(
                safeLine,
                style: isHeading
                    ? pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                        font: boldFont,
                      )
                    : isSubHeading
                        ? pw.TextStyle(
                            fontSize: 11.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey700,
                            font: boldFont,
                          )
                        : pw.TextStyle(
                            fontSize: 10.5,
                            height: 1.35,
                            color: PdfColors.black,
                            font: regularFont,
                          ),
                textAlign: pw.TextAlign.left,
                softWrap: true,
                maxLines: null,
              ),
            );
          }),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.blueGrey200),
          pw.SizedBox(height: 4),
          pw.Text(
            'Exported from the mobile app',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.blueGrey500,
              font: regularFont,
            ),
          ),
        ],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pdfContext) => [
          pw.Text(
            'Visualizations',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Simple explanation: In the category chart, longer bars mean higher spending. In the weekly chart, green bars indicate surplus and red bars indicate deficit.',
            style: pw.TextStyle(
              fontSize: 10.5,
              color: PdfColors.blueGrey700,
              font: regularFont,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Category Spending Plot',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 6),
          ...payload.topCategoryPoints.isEmpty
              ? [
                  pw.Text(
                    'No category spending data available this month.',
                    style: pw.TextStyle(font: regularFont),
                  )
                ]
              : payload.topCategoryPoints.map((point) {
                  final ratio =
                      maxCategory <= 0 ? 0.0 : point.value / maxCategory;
                  final barWidth = 180 * ratio;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(
                          width: 90,
                          child: pw.Text(
                            safePdfText(point.key),
                            style:
                                pw.TextStyle(fontSize: 10, font: regularFont),
                          ),
                        ),
                        pw.Container(
                          width: 180,
                          height: 10,
                          color: PdfColors.blueGrey100,
                          child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Container(
                              width: barWidth < 2 ? 2 : barWidth,
                              height: 10,
                              color: PdfColors.blue700,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'BDT ${point.value.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 10, font: regularFont),
                        ),
                      ],
                    ),
                  );
                }),
          pw.SizedBox(height: 4),
          pw.Text(
            'Simple explanation: A longer bar means more spending in that category.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.blueGrey700,
              font: regularFont,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Weekly Net Cashflow Plot',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 6),
          ...payload.weeklyTrendValues.isEmpty
              ? [
                  pw.Text(
                    'No weekly trend data available.',
                    style: pw.TextStyle(font: regularFont),
                  )
                ]
              : payload.weeklyTrendValues.asMap().entries.map((entry) {
                  final week = entry.key + 1;
                  final value = entry.value;
                  final ratio =
                      maxWeeklyAbs <= 0 ? 0.0 : value.abs() / maxWeeklyAbs;
                  final barWidth = 180 * ratio;
                  final barColor =
                      value >= 0 ? PdfColors.green700 : PdfColors.red700;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(
                          width: 90,
                          child: pw.Text(
                            'Week $week',
                            style:
                                pw.TextStyle(fontSize: 10, font: regularFont),
                          ),
                        ),
                        pw.Container(
                          width: 180,
                          height: 10,
                          color: PdfColors.blueGrey100,
                          child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Container(
                              width: barWidth < 2 ? 2 : barWidth,
                              height: 10,
                              color: barColor,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'BDT ${value.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 10, font: regularFont),
                        ),
                      ],
                    ),
                  );
                }),
          pw.SizedBox(height: 4),
          pw.Text(
            'Simple explanation: Green bars mean weekly surplus, red bars mean weekly deficit.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.blueGrey700,
              font: regularFont,
            ),
          ),
        ],
      ),
    );

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'finance_report_$timestamp';
    final bytes = await doc.save();

    try {
      String? savedPath;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        savedPath = await _downloadsChannel.invokeMethod<String>(
          'savePdfToDownloads',
          {
            'fileName': '$fileName.pdf',
            'bytes': bytes,
          },
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF download is supported on Android app build.'),
          ),
        );
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath == null || savedPath.isEmpty
                ? 'PDF saved to Downloads.'
                : 'PDF saved: $savedPath',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download failed. Please try again.'),
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchForecast(
      List<Transaction> transactions) async {
    final now = DateTime.now();
    if (_forecastCache != null &&
        _forecastCacheAt != null &&
        now.difference(_forecastCacheAt!).inMinutes < 3) {
      return _forecastCache!;
    }

    try {
      final backendUrl = '$_apiBaseUrl/api/v1/insights/forecast';
      final response = await http
          .get(
            Uri.parse('$backendUrl?user_id=1'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10))
          .onError((error, stack) => http.Response('[]', 404));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return transactions.isNotEmpty
            ? _localForecastForTransactions(transactions)
            : [];
      }

      final List<dynamic> data = json.decode(response.body);
      final rows = data
          .map((item) => {
                'period': item['period'] ?? 'N/A',
                'predicted_expense':
                    item['predicted_expense']?.toString() ?? '0',
              })
          .toList();
      if (rows.isEmpty && transactions.isNotEmpty) {
        return _localForecastForTransactions(transactions);
      }
      _forecastCache = rows;
      _forecastCacheAt = now;
      return rows;
    } catch (e) {
      return transactions.isNotEmpty
          ? _localForecastForTransactions(transactions)
          : [];
    }
  }

  List<Map<String, dynamic>> _localForecastForTransactions(
      List<Transaction> transactions) {
    final nextMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      1,
    );
    final predictedExpense = _estimateNextMonthExpense(transactions);

    return [
      {
        'period':
            '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}',
        'predicted_expense': predictedExpense.toStringAsFixed(0),
      },
    ];
  }

  double _estimateNextMonthExpense(List<Transaction> transactions) {
    final recentAverage = _averageMonthlyExpense(transactions, 3);
    if (recentAverage > 0) {
      return recentAverage;
    }

    final expenseTotal = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final monthCount = transactions
        .where((t) => t.type == TransactionType.expense)
        .map((t) => '${t.date.year}-${t.date.month}')
        .toSet()
        .length;
    return monthCount > 0 ? expenseTotal / monthCount : expenseTotal;
  }

  List<String> _generateRecommendations(
    List<Transaction> transactions,
    double totalIncome,
    double totalSpent,
    double saved,
  ) {
    if (transactions.isEmpty) {
      return [
        'No transaction yet. Add at least 5 entries to get personalized recommendations.',
        'Start by tracking daily groceries and transport to improve prediction quality.',
        'Set a starter weekly savings target, for example ৳1,000.',
      ];
    }

    final results = <String>[];
    final expenseTxns =
        transactions.where((t) => t.type == TransactionType.expense).toList();
    final incomeTxns =
        transactions.where((t) => t.type == TransactionType.income).toList();

    if (saved < 0) {
      final overshoot = saved.abs();
      results.add(
        'You are over budget by ৳${overshoot.toStringAsFixed(0)}. Reduce flexible spending by at least ৳${(overshoot * 0.6).toStringAsFixed(0)} next month.',
      );
    } else {
      final saveRate = totalIncome > 0 ? (saved / totalIncome) * 100 : 0.0;
      if (saveRate >= 20) {
        results.add(
          'Great savings rate (${saveRate.toStringAsFixed(0)}%). Keep this pace and move part of surplus to emergency funds.',
        );
      } else {
        results.add(
          'Current savings rate is ${saveRate.toStringAsFixed(0)}%. Target at least 20% by reducing non-essential expenses.',
        );
      }
    }

    if (expenseTxns.isNotEmpty) {
      final categoryTotals = <String, double>{};
      for (final txn in expenseTxns) {
        categoryTotals[txn.category] =
            (categoryTotals[txn.category] ?? 0) + txn.amount;
      }
      final topCategory =
          categoryTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      results.add(
        'Highest spending category: ${topCategory.key} (৳${topCategory.value.toStringAsFixed(0)}). Set a category cap and review weekly.',
      );
    }

    final walletFeesCount = transactions
        .where((t) => t.category.toLowerCase().contains('wallet'))
        .length;
    if (walletFeesCount >= 3) {
      results.add(
        'Frequent wallet fee activity detected. Batch bKash/Nagad cash-outs to reduce charges.',
      );
    }

    if (incomeTxns.length <= 1) {
      results.add(
        'Income entries are limited. Track all income sources to improve budget accuracy.',
      );
    }

    return results.take(4).toList();
  }

  _SmartBudgetCopilotPlan _buildSmartBudgetCopilot(
    List<Transaction> transactions,
    double targetSavingsRate,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = monthEnd.day;
    final elapsedDays = max(1, now.day);
    final remainingDays = max(1, daysInMonth - elapsedDays);

    final incomeThisMonth = transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final expenseThisMonthTransactions = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .toList();
    final expenseThisMonth = expenseThisMonthTransactions.fold<double>(
        0, (sum, t) => sum + t.amount);

    final historicalExpense = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(monthStart.subtract(const Duration(days: 90))))
        .toList();

    final incomeEstimate =
        incomeThisMonth > 0 ? incomeThisMonth : _estimateIncome(transactions);
    final targetExpenseBudget =
        max(0.0, incomeEstimate * (1 - targetSavingsRate / 100));

    final projectedMonthEndExpense =
        (expenseThisMonth / elapsedDays) * daysInMonth;
    final expectedSpendByToday =
        (targetExpenseBudget / daysInMonth) * elapsedDays;
    final paceGap = expenseThisMonth - expectedSpendByToday;
    final isAtRisk = projectedMonthEndExpense > targetExpenseBudget;

    final remainingBudget = targetExpenseBudget - expenseThisMonth;
    final double safeDailySpend =
        remainingBudget > 0 ? remainingBudget / remainingDays : 0.0;

    final categoryWeights = _computeCategoryWeights(historicalExpense);
    final categorySpentThisMonth = <String, double>{};
    for (final txn in expenseThisMonthTransactions) {
      categorySpentThisMonth[txn.category] =
          (categorySpentThisMonth[txn.category] ?? 0) + txn.amount;
    }

    final categoryPlans = <_CategoryBudgetPlan>[];
    categoryWeights.forEach((category, weight) {
      categoryPlans.add(
        _CategoryBudgetPlan(
          category: category,
          recommendedBudget: targetExpenseBudget * weight,
          currentSpent: categorySpentThisMonth[category] ?? 0,
        ),
      );
    });
    categoryPlans
        .sort((a, b) => b.recommendedBudget.compareTo(a.recommendedBudget));

    final neededCut = max(0.0, projectedMonthEndExpense - targetExpenseBudget);
    final cutSuggestions = <_CategoryCutSuggestion>[];
    if (neededCut > 0 && categorySpentThisMonth.isNotEmpty) {
      final sortedCategories = categorySpentThisMonth.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final totalTopSpent =
          sortedCategories.fold<double>(0, (sum, e) => sum + e.value);

      for (final entry in sortedCategories.take(3)) {
        final share = totalTopSpent > 0 ? entry.value / totalTopSpent : 0;
        final cut = neededCut * share;
        if (cut >= 50) {
          cutSuggestions.add(
            _CategoryCutSuggestion(
              category: entry.key,
              recommendedCut: cut,
            ),
          );
        }
      }
    }

    return _SmartBudgetCopilotPlan(
      targetExpenseBudget: targetExpenseBudget,
      projectedMonthEndExpense: projectedMonthEndExpense,
      safeDailySpend: safeDailySpend,
      paceGap: paceGap,
      isAtRisk: isAtRisk,
      categoryPlans: categoryPlans,
      cutSuggestions: cutSuggestions,
    );
  }

  double _estimateIncome(List<Transaction> transactions) {
    final incomeTxns =
        transactions.where((t) => t.type == TransactionType.income).toList();
    if (incomeTxns.isEmpty) {
      return 0;
    }

    final monthlyIncome = <String, double>{};
    for (final txn in incomeTxns) {
      final key =
          '${txn.date.year}-${txn.date.month.toString().padLeft(2, '0')}';
      monthlyIncome[key] = (monthlyIncome[key] ?? 0) + txn.amount;
    }

    final values = monthlyIncome.values.toList();
    return values.fold<double>(0, (sum, value) => sum + value) / values.length;
  }

  Map<String, double> _computeCategoryWeights(List<Transaction> expenseTxns) {
    if (expenseTxns.isEmpty) {
      return {'general': 1.0};
    }

    final totals = <String, double>{};
    for (final txn in expenseTxns) {
      totals[txn.category] = (totals[txn.category] ?? 0) + txn.amount;
    }

    final totalAmount =
        totals.values.fold<double>(0, (sum, value) => sum + value);
    if (totalAmount <= 0) {
      return {'general': 1.0};
    }

    final weights = <String, double>{};
    totals.forEach((category, amount) {
      weights[category] = amount / totalAmount;
    });
    return weights;
  }

  _FinancialHealthResult _calculateFinancialHealth(
    List<Transaction> transactions,
  ) {
    final now = DateTime.now();
    final monthTxns = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    final monthIncome = monthTxns
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final monthExpense = monthTxns
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final savingsRate =
        monthIncome > 0 ? ((monthIncome - monthExpense) / monthIncome) : 0.0;
    final savingsRateLinear = (((savingsRate + 0.10) / 0.40) * 100)
        .clamp(0.0, 100.0); // rewards >=10%-30% savings faster
    final incomeCoverage =
        monthExpense > 0 ? (monthIncome / monthExpense) : 1.2;
    final coverageScore =
        (((incomeCoverage - 0.80) / 0.70) * 100).clamp(0.0, 100.0);
    final savingsRateScore =
        ((savingsRateLinear * 0.6) + (coverageScore * 0.4)).clamp(0.0, 100.0);

    final weeklyNet = _lastWeeklyNetCashflows(transactions, 8);
    final avgWeekly = weeklyNet.isEmpty
        ? 0.0
        : weeklyNet.fold<double>(0, (sum, v) => sum + v) / weeklyNet.length;
    final variance = weeklyNet.isEmpty
        ? 0.0
        : weeklyNet.fold<double>(0, (sum, v) => sum + pow(v - avgWeekly, 2)) /
            weeklyNet.length;
    final stdDev = sqrt(variance);
    final stabilityRatio =
        avgWeekly.abs() > 0 ? (stdDev / avgWeekly.abs()) : 1.0;
    final cashflowStabilityScore =
        (100 / (1 + stabilityRatio)).clamp(25.0, 100.0);

    final expenseTxns =
        transactions.where((t) => t.type == TransactionType.expense).toList();
    final categoryTotals = <String, double>{};
    for (final txn in expenseTxns) {
      categoryTotals[txn.category] =
          (categoryTotals[txn.category] ?? 0) + txn.amount;
    }
    final totalExpense =
        categoryTotals.values.fold<double>(0, (sum, value) => sum + value);
    final topCategoryShare = totalExpense > 0
        ? (categoryTotals.values.isEmpty
            ? 1.0
            : categoryTotals.values.reduce(max) / totalExpense)
        : 1.0;
    final categoryConcentrationScore =
        ((1 - topCategoryShare) * 100).clamp(20.0, 100.0);

    final totalIncomeAll = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpenseAll = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final netBalance = totalIncomeAll - totalExpenseAll;
    final avgMonthlyExpense = _averageMonthlyExpense(transactions, 3);
    final runwayMonths =
        avgMonthlyExpense > 0 ? netBalance / avgMonthlyExpense : 0.0;
    final runwayScore = ((runwayMonths / 6) * 100).clamp(0.0, 100.0);

    final score = (savingsRateScore * 0.45) +
        (cashflowStabilityScore * 0.20) +
        (categoryConcentrationScore * 0.15) +
        (runwayScore * 0.20);

    final trend = _buildWeeklyHealthTrend(transactions);

    return _FinancialHealthResult(
      score: score,
      label: score >= 70
          ? 'Strong financial health'
          : score >= 45
              ? 'Moderate, can improve'
              : 'Needs attention',
      savingsRateScore: savingsRateScore,
      cashflowStabilityScore: cashflowStabilityScore,
      categoryConcentrationScore: categoryConcentrationScore,
      runwayScore: runwayScore,
      weeklyTrend: trend,
    );
  }

  List<double> _lastWeeklyNetCashflows(
    List<Transaction> transactions,
    int weeks,
  ) {
    final now = DateTime.now();
    final result = <double>[];

    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final income = transactions
          .where((t) =>
              t.type == TransactionType.income &&
              !t.date.isBefore(weekStart) &&
              t.date.isBefore(weekEnd))
          .fold<double>(0, (sum, t) => sum + t.amount);
      final expense = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              !t.date.isBefore(weekStart) &&
              t.date.isBefore(weekEnd))
          .fold<double>(0, (sum, t) => sum + t.amount);
      result.add(income - expense);
    }
    return result;
  }

  double _averageMonthlyExpense(List<Transaction> transactions, int months) {
    final now = DateTime.now();
    var sum = 0.0;
    var counted = 0;

    for (var i = 0; i < months; i++) {
      final target = DateTime(now.year, now.month - i, 1);
      final expense = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == target.year &&
              t.date.month == target.month)
          .fold<double>(0, (acc, t) => acc + t.amount);
      if (expense > 0) {
        sum += expense;
        counted++;
      }
    }
    return counted > 0 ? sum / counted : 0.0;
  }

  List<_WeeklyHealthPoint> _buildWeeklyHealthTrend(
    List<Transaction> transactions,
  ) {
    final points = <_WeeklyHealthPoint>[];
    final now = DateTime.now();

    for (var i = 5; i >= 0; i--) {
      final cutoff = now.subtract(Duration(days: i * 7));
      final subset =
          transactions.where((t) => !t.date.isAfter(cutoff)).toList();
      final snapshot = _calculateFinancialHealthSnapshot(subset);
      points.add(_WeeklyHealthPoint(label: 'W${6 - i}', score: snapshot));
    }
    return points;
  }

  double _calculateFinancialHealthSnapshot(List<Transaction> txns) {
    if (txns.isEmpty) {
      return 0;
    }
    final income = txns
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = txns
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final saveRate = income > 0 ? ((income - expense) / income) : 0.0;
    return (saveRate * 100).clamp(0.0, 100.0);
  }

  _OverspendingWarning _buildOverspendingWarning(
    List<Transaction> transactions,
    _SmartBudgetCopilotPlan copilotPlan,
  ) {
    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = monthEnd.day;
    final elapsedDays = max(1, now.day);
    final currentMonthExpense = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final dailyPace = currentMonthExpense / elapsedDays;
    final remainingBudget =
        copilotPlan.targetExpenseBudget - currentMonthExpense;
    int? daysToCross;

    if (dailyPace > 0 && remainingBudget > 0) {
      daysToCross = (remainingBudget / dailyPace).floor();
    }

    final isWarning = copilotPlan.isAtRisk &&
        (daysToCross == null || daysToCross <= (daysInMonth - elapsedDays));

    final categoryTotals = <String, double>{};
    for (final txn in transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month)) {
      categoryTotals[txn.category] =
          (categoryTotals[txn.category] ?? 0) + txn.amount;
    }
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final fixes = <String>[];
    if (topCategories.isNotEmpty) {
      fixes.add(
        'Cut ${topCategories.first.key} by 15% this week (about ৳${(topCategories.first.value * 0.15).toStringAsFixed(0)}).',
      );
    }
    if (topCategories.length > 1) {
      fixes.add(
        'Pause optional spending in ${topCategories[1].key} until next salary cycle.',
      );
    }
    fixes.add(
      'Keep daily expense under ৳${copilotPlan.safeDailySpend.toStringAsFixed(0)} to stay within budget.',
    );

    final message = !isWarning
        ? 'You are currently on track. At this pace, you are unlikely to exceed this month\'s budget.'
        : daysToCross == null
            ? 'Your spending pace is above budget and may cross the limit before month-end.'
            : 'At this pace, you may cross your budget in about $daysToCross days.';

    return _OverspendingWarning(
      isWarning: isWarning,
      message: message,
      daysToCross: daysToCross,
      fixes: fixes.take(3).toList(),
    );
  }

  String _buildForecastExplanation(
    List<Transaction> transactions,
    List<Map<String, dynamic>> forecasts,
  ) {
    if (forecasts.isNotEmpty) {
      final values = forecasts
          .map((f) => double.tryParse(f['predicted_expense'].toString()) ?? 0)
          .where((v) => v >= 0)
          .toList();
      if (values.isNotEmpty) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        final maxVal = values.reduce((a, b) => a > b ? a : b);
        final minVal = values.reduce((a, b) => a < b ? a : b);
        return 'Estimated next-month expense range is ৳${minVal.toStringAsFixed(0)} to ৳${maxVal.toStringAsFixed(0)}, with average around ৳${avg.toStringAsFixed(0)} based on recent behavior.';
      }
    }

    final now = DateTime.now();
    final recentStart = now.subtract(const Duration(days: 21));
    final previousStart = now.subtract(const Duration(days: 42));

    final recent = transactions.where((t) =>
        t.type == TransactionType.expense &&
        !t.date.isBefore(recentStart) &&
        !t.date.isAfter(now));
    final previous = transactions.where((t) =>
        t.type == TransactionType.expense &&
        !t.date.isBefore(previousStart) &&
        t.date.isBefore(recentStart));

    final recentByCategory = <String, double>{};
    final previousByCategory = <String, double>{};

    for (final txn in recent) {
      recentByCategory[txn.category] =
          (recentByCategory[txn.category] ?? 0) + txn.amount;
    }
    for (final txn in previous) {
      previousByCategory[txn.category] =
          (previousByCategory[txn.category] ?? 0) + txn.amount;
    }

    if (recentByCategory.isEmpty) {
      return 'Recent expense history is limited, so forecast leans more on baseline trend.';
    }

    String topCategory = recentByCategory.keys.first;
    double maxGrowthPct = -999;
    for (final entry in recentByCategory.entries) {
      final prev = previousByCategory[entry.key] ?? 0;
      if (prev <= 0) {
        continue;
      }
      final growthPct = ((entry.value - prev) / prev) * 100;
      if (growthPct > maxGrowthPct) {
        maxGrowthPct = growthPct;
        topCategory = entry.key;
      }
    }

    final forecastDirection = forecasts.isNotEmpty
        ? ((double.tryParse(forecasts.first['predicted_expense'].toString()) ??
                    0) >
                recentByCategory.values.fold<double>(0, (s, v) => s + v)
            ? 'up'
            : 'steady or lower')
        : 'trend estimate';

    if (maxGrowthPct == -999) {
      return 'Spending mix changed recently, so next-month estimate follows this updated pattern ($forecastDirection).';
    }

    return 'In the last 3 weeks, $topCategory expense changed by ${maxGrowthPct.toStringAsFixed(0)}%, so next-month trend looks $forecastDirection.';
  }

  String _expenseComparisonText(List<Transaction> transactions) {
    final now = DateTime.now();
    final thisMonthExpense = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonthExpense = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == lastMonthDate.year &&
            t.date.month == lastMonthDate.month)
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (lastMonthExpense <= 0 && thisMonthExpense <= 0) {
      return 'No monthly expense history yet for comparison.';
    }
    if (lastMonthExpense <= 0) {
      return 'No expense found for last month. This month total expense is ৳${thisMonthExpense.toStringAsFixed(0)}.';
    }

    final changePct =
        ((thisMonthExpense - lastMonthExpense) / lastMonthExpense) * 100;
    final direction = changePct >= 0 ? 'up' : 'down';
    return 'Last month vs this month: expense is ${changePct.abs().toStringAsFixed(1)}% $direction.';
  }

  _WhatIfResult _simulateWhatIf(
    List<Transaction> transactions,
    String scenario,
  ) {
    final now = DateTime.now();
    final loweredScenario = scenario.toLowerCase();
    final isIncomeScenario =
        ['earn', 'income', 'bonus', 'salary'].any(loweredScenario.contains);
    final isPurchaseScenario =
        ['buy', 'purchase', 'spend on'].any(loweredScenario.contains);

    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = monthEnd.day;
    final elapsedDays = max(1, now.day);
    final lookbackStart = now.subtract(const Duration(days: 30));

    final monthlyIncome = transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final monthlyExpenseTxns = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .toList();

    final recentExpenseTxns = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            (t.date.isAfter(lookbackStart) ||
                t.date.isAtSameMomentAs(lookbackStart)))
        .toList();

    final workingExpenseTxns =
        monthlyExpenseTxns.isNotEmpty ? monthlyExpenseTxns : recentExpenseTxns;

    final baseExpense =
        workingExpenseTxns.fold<double>(0, (sum, t) => sum + t.amount);
    final projectedBaseExpense = monthlyExpenseTxns.isNotEmpty
        ? (baseExpense / elapsedDays) * daysInMonth
        : baseExpense;
    final incomeEstimate =
        monthlyIncome > 0 ? monthlyIncome : _estimateIncome(transactions);

    if (workingExpenseTxns.isEmpty || incomeEstimate <= 0) {
      return _WhatIfResult(
        summary:
            'Not enough data for simulation. Add some income and expense records first.',
        projectedSavings: 0,
        endOfMonthCash: 0,
        riskScore: 0.50,
        riskLevel: 'medium',
      );
    }

    if (isIncomeScenario) {
      final addedIncome = _extractAmount(scenario) ?? 5000;
      final simulatedIncome = incomeEstimate + addedIncome;
      final projectedSavings = simulatedIncome - projectedBaseExpense;
      final riskScore = _riskFromExpense(simulatedIncome, projectedBaseExpense);

      return _WhatIfResult(
        summary:
            'If you earn an extra ৳${addedIncome.toStringAsFixed(0)}, your projected savings will increase.',
        projectedSavings: projectedSavings,
        endOfMonthCash: projectedSavings,
        riskScore: riskScore,
        riskLevel: _riskLevel(riskScore),
      );
    }

    if (isPurchaseScenario) {
      final purchaseAmount = _extractAmount(scenario) ?? 20000;
      final simulatedExpense = projectedBaseExpense + purchaseAmount;
      final projectedSavings = incomeEstimate - simulatedExpense;
      final riskScore = _riskFromExpense(incomeEstimate, simulatedExpense);

      return _WhatIfResult(
        summary:
            'A one-time purchase of ৳${purchaseAmount.toStringAsFixed(0)} will increase your monthly spend.',
        projectedSavings: projectedSavings,
        endOfMonthCash: projectedSavings,
        riskScore: riskScore,
        riskLevel: _riskLevel(riskScore),
      );
    }

    final parsedPercent = _extractPercent(scenario); // Reduction scenario
    final reductionPct =
        parsedPercent == null ? 10.0 : parsedPercent.clamp(1.0, 80.0);
    final targetCategory = _extractCategory(scenario, workingExpenseTxns);
    final targetCanonical = _canonicalCategory(targetCategory);

    final categorySpend = workingExpenseTxns
        .where((t) => _canonicalCategory(t.category) == targetCanonical)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final matchedCategoryName = workingExpenseTxns
        .where((t) => _canonicalCategory(t.category) == targetCanonical)
        .map((t) => t.category)
        .fold<String?>(null, (prev, curr) => prev ?? curr);

    if (categorySpend <= 0) {
      return _WhatIfResult(
        summary:
            'Category not found in this month records. Try a category like food, transport, rent.',
        projectedSavings: max(0, incomeEstimate - projectedBaseExpense),
        endOfMonthCash: incomeEstimate - projectedBaseExpense,
        riskScore: _riskFromExpense(incomeEstimate, projectedBaseExpense),
        riskLevel:
            _riskLevel(_riskFromExpense(incomeEstimate, projectedBaseExpense)),
      );
    }

    final cutAmount = categorySpend * (reductionPct / 100);
    final simulatedExpense = max(0.0, projectedBaseExpense - cutAmount);
    final projectedSavings = incomeEstimate - simulatedExpense;
    final riskScore = _riskFromExpense(incomeEstimate, simulatedExpense);

    return _WhatIfResult(
      summary:
          'If you reduce ${matchedCategoryName ?? targetCategory} by ${reductionPct.toStringAsFixed(0)}%, estimated monthly spend drops by ৳${cutAmount.toStringAsFixed(0)}.',
      projectedSavings: projectedSavings,
      endOfMonthCash: projectedSavings,
      riskScore: riskScore,
      riskLevel: _riskLevel(riskScore),
    );
  }

  double? _extractPercent(String text) {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(text);
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(1) ?? '');
  }

  double? _extractAmount(String text) {
    final match =
        RegExp(r'(?:taka|bdt|tk|৳)?\s*([0-9,]+(?:\.\d+)?)').firstMatch(text);
    if (match == null) return null;
    final amountString = match.group(1)?.replaceAll(',', '') ?? '';
    return double.tryParse(amountString);
  }

  String _extractCategory(String text, List<Transaction> monthlyExpenseTxns) {
    final lowered = text.toLowerCase();
    final aliases = <String, String>{
      'transport': 'transport',
      'transportation': 'transport',
      'travel': 'transport',
      'commute': 'transport',
      'ride': 'transport',
      'bus': 'transport',
      'গাড়ি': 'transport',
      'বাস': 'transport',
      'food': 'food',
      'খাবার': 'food',
      'grocery': 'groceries',
      'groceries': 'groceries',
      'rent': 'rent',
      'ভাড়া': 'rent',
      'utility': 'utilities',
      'utilities': 'utilities',
      'shopping': 'shopping',
    };

    for (final entry in aliases.entries) {
      if (lowered.contains(entry.key)) {
        return entry.value;
      }
    }

    for (final txn in monthlyExpenseTxns) {
      final category = txn.category.toLowerCase();
      if (lowered.contains(category)) {
        return txn.category;
      }
    }

    return monthlyExpenseTxns.first.category;
  }

  String _canonicalCategory(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('transport') ||
        v.contains('travel') ||
        v.contains('commute') ||
        v.contains('ride') ||
        v.contains('bus') ||
        v.contains('গাড়ি') ||
        v.contains('বাস')) {
      return 'transport';
    }
    if (v.contains('food') || v.contains('খাবার')) {
      return 'food';
    }
    if (v.contains('grocery')) {
      return 'groceries';
    }
    if (v.contains('rent') || v.contains('ভাড়া')) {
      return 'rent';
    }
    if (v.contains('utility')) {
      return 'utilities';
    }
    if (v.contains('shopping')) {
      return 'shopping';
    }
    return v.replaceAll(RegExp(r'[^a-z0-9\u0980-\u09FF]+'), '');
  }

  double _riskFromExpense(double income, double expense) {
    if (income <= 0) {
      return 0.90;
    }
    final ratio = expense / income;
    return ratio.clamp(0.0, 1.5) / 1.5;
  }

  String _riskLevel(double riskScore) {
    if (riskScore >= 0.75) {
      return 'high';
    }
    if (riskScore >= 0.45) {
      return 'medium';
    }
    return 'low';
  }

  Widget _buildRecommendation(BuildContext context, String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartBudgetCopilotPlan {
  final double targetExpenseBudget;
  final double projectedMonthEndExpense;
  final double safeDailySpend;
  final double paceGap;
  final bool isAtRisk;
  final List<_CategoryBudgetPlan> categoryPlans;
  final List<_CategoryCutSuggestion> cutSuggestions;

  _SmartBudgetCopilotPlan({
    required this.targetExpenseBudget,
    required this.projectedMonthEndExpense,
    required this.safeDailySpend,
    required this.paceGap,
    required this.isAtRisk,
    required this.categoryPlans,
    required this.cutSuggestions,
  });
}

class _CategoryBudgetPlan {
  final String category;
  final double recommendedBudget;
  final double currentSpent;

  _CategoryBudgetPlan({
    required this.category,
    required this.recommendedBudget,
    required this.currentSpent,
  });
}

class _CategoryCutSuggestion {
  final String category;
  final double recommendedCut;

  _CategoryCutSuggestion({
    required this.category,
    required this.recommendedCut,
  });
}

class _WhatIfResult {
  final String summary;
  final double projectedSavings;
  final double endOfMonthCash;
  final double riskScore;
  final String riskLevel;

  _WhatIfResult({
    required this.summary,
    required this.projectedSavings,
    required this.endOfMonthCash,
    required this.riskScore,
    required this.riskLevel,
  });
}

class _FinancialHealthResult {
  final double score;
  final String label;
  final double savingsRateScore;
  final double cashflowStabilityScore;
  final double categoryConcentrationScore;
  final double runwayScore;
  final List<_WeeklyHealthPoint> weeklyTrend;

  _FinancialHealthResult({
    required this.score,
    required this.label,
    required this.savingsRateScore,
    required this.cashflowStabilityScore,
    required this.categoryConcentrationScore,
    required this.runwayScore,
    required this.weeklyTrend,
  });
}

class _WeeklyHealthPoint {
  final String label;
  final double score;

  _WeeklyHealthPoint({
    required this.label,
    required this.score,
  });
}

class _OverspendingWarning {
  final bool isWarning;
  final String message;
  final int? daysToCross;
  final List<String> fixes;

  _OverspendingWarning({
    required this.isWarning,
    required this.message,
    required this.daysToCross,
    required this.fixes,
  });
}

class _GeneratedReportPayload {
  final String narrative;
  final String csv;
  final List<MapEntry<String, double>> topCategoryPoints;
  final List<double> weeklyTrendValues;

  _GeneratedReportPayload({
    required this.narrative,
    required this.csv,
    required this.topCategoryPoints,
    required this.weeklyTrendValues,
  });
}
