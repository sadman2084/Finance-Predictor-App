import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/debt_model.dart';
import '../models/transaction_model.dart';
import '../state/transaction_store.dart';

class MoreTab extends StatefulWidget {
  const MoreTab({Key? key}) : super(key: key);

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 6,
      child: Column(
        children: [
          Material(
            elevation: 1,
            child: TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.sms), text: 'SMS'),
                Tab(icon: Icon(Icons.document_scanner), text: 'Receipt'),
                Tab(icon: Icon(Icons.health_and_safety), text: 'Emergency'),
                Tab(icon: Icon(Icons.account_balance), text: 'Debt'),
                Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
                Tab(icon: Icon(Icons.chat), text: 'Assistant'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SmsImportPanel(),
                _ReceiptScannerPanel(),
                _EmergencyFundPanel(),
                _DebtTrackerPanel(),
                _CashflowCalendarPanel(),
                _AssistantChatPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsImportPanel extends StatefulWidget {
  const _SmsImportPanel();

  @override
  State<_SmsImportPanel> createState() => _SmsImportPanelState();
}

class _SmsImportPanelState extends State<_SmsImportPanel> {
  final _controller = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _parsed;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PanelScaffold(
      title: 'SMS / Bank Message Import',
      children: [
        // Example SMS card
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How it works',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800)),
                      const SizedBox(height: 4),
                      Text(
                        'Paste any SMS from bKash, Nagad, Rocket, or your bank. '
                        'The app will auto-detect the amount, category, and transaction type.',
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Example toggle
        TextButton.icon(
          onPressed: () {
            _controller.text = 'Sent BDT 1,500 to 01XXXXXXXXX via bKash at 12:45 PM. '
                'Fee BDT 5.00. Ref XXX. Balance BDT 10,200.00.';
            setState(() {});
          },
          icon: const Icon(Icons.preview, size: 18),
          label: const Text('Tap to insert example SMS'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Paste your transaction SMS here...',
            labelText: 'SMS Text',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _loading || _controller.text.trim().isEmpty ? null : _parse,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_fix_high),
          label: Text(_loading ? 'Analyzing...' : 'Parse & Import'),
        ),
        if (_parsed != null) ...[
          const SizedBox(height: 16),
          _ParsedTransactionCard(
            parsed: _parsed!,
            onSave: () => _saveParsed(context, _parsed!),
          ),
        ],
      ],
    );
  }

  Future<void> _parse() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);
    // Simulate a short delay for realistic UX
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final parsed = _parseSmsLocally(_controller.text.trim());
      setState(() => _parsed = parsed);
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Could not parse message: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _parseSmsLocally(String message) {
    // Extract amount (supports BDT 1,500, BDT 1500, 1500TK, etc.)
    final amountRegex = RegExp(r'(?:BDT|TK|Tk|tk)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
    final amountMatches = amountRegex.allMatches(message);
    double? amount;
    for (final match in amountMatches) {
      final cleaned = match.group(1)!.replaceAll(',', '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null && parsed >= 10 && parsed <= 9999999) {
        amount = parsed;
        break;
      }
    }

    // Determine transaction type
    final lower = message.toLowerCase();
    final isSent = lower.contains('sent') || lower.contains('paid') || lower.contains('transfer');
    final isReceived = lower.contains('received') || lower.contains('credit') || lower.contains('cash in');
    final isExpense = isSent && !isReceived;
    final isIncome = isReceived && !isSent;

    // Determine channel
    String channel = 'cash';
    if (lower.contains('bkash')) channel = 'bkash';
    else if (lower.contains('nagad')) channel = 'nagad';
    else if (lower.contains('rocket')) channel = 'rocket';
    else if (lower.contains('card') || lower.contains('bank')) channel = 'bank';

    // Determine category
    String category = 'shopping';
    if (lower.contains('salary') || lower.contains('income') || lower.contains('payment received')) {
      category = 'salary';
    } else if (lower.contains('fee') || lower.contains('charge') || lower.contains('service')) {
      category = 'services';
    } else if (lower.contains('bill') || lower.contains('electric') || lower.contains('gas') || lower.contains('water')) {
      category = 'utilities';
    } else if (lower.contains('food') || lower.contains('meal') || lower.contains('restaurant')) {
      category = 'food';
    } else if (lower.contains('transport') || lower.contains('bus') || lower.contains('fuel')) {
      category = 'transport';
    }

    // Extract date
    DateTime txnDate = DateTime.now();
    final dateRegex = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})');
    final dateMatch = dateRegex.firstMatch(message);
    if (dateMatch != null) {
      final parts = dateMatch.group(1)!.split(RegExp(r'[/-]'));
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]) ?? 1;
        final month = int.tryParse(parts[1]) ?? 1;
        final yearStr = parts[2];
        final year = yearStr.length == 2 ? 2000 + int.parse(yearStr) : int.parse(yearStr);
        txnDate = DateTime(year, month, day);
      }
    }

    // Extract description
    String description = '';
    if (isSent && !lower.contains('bkash') && !lower.contains('nagad') && !lower.contains('rocket')) {
      final toIdx = lower.indexOf('to');
      if (toIdx >= 0) {
        final rest = message.substring(toIdx + 2).trim();
        final endIdx = rest.indexOf('at');
        if (endIdx >= 0) {
          description = rest.substring(0, endIdx).trim();
        } else {
          description = rest.split(RegExp(r'\s+')).take(3).join(' ');
        }
      }
    }
    if (description.isEmpty) {
      if (isSent) description = 'Payment sent';
      else if (isReceived) description = 'Payment received';
      else description = 'Transaction';
    }

    return {
      'amount': amount ?? 0.0,
      'category': category,
      'channel': channel,
      'description': description,
      'txn_date': txnDate.toIso8601String(),
      'type': isIncome ? 'income' : 'expense',
    };
  }
}

class _ReceiptScannerPanel extends StatefulWidget {
  const _ReceiptScannerPanel();

  @override
  State<_ReceiptScannerPanel> createState() => _ReceiptScannerPanelState();
}

class _ReceiptScannerPanelState extends State<_ReceiptScannerPanel> {
  final _textController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _parsed;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PanelScaffold(
      title: 'Manual Receipt Entry',
      children: [
        // Instructions card
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How it works',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800)),
                      const SizedBox(height: 4),
                      Text(
                        'Type the receipt details manually.\n'
                        'Include: store name, items, and total amount.\n'
                        'The app will extract the key information.',
                        style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Receipt text input
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      radius: 16,
                      child: Icon(Icons.receipt, color: Colors.orange.shade700, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Enter Receipt Details',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _textController,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Store: Fresh Mart\nItems: Rice, Eggs, Oil\nTotal: BDT 850',
                    labelText: 'Receipt text',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Quick fill buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('🛒 Grocery'),
                      onPressed: () {
                        _textController.text =
                            'Store: Agora Super Shop\nItems: Rice 5kg, Soybean Oil, Eggs, Sugar\nTotal: BDT 1,250';
                        setState(() {});
                      },
                    ),
                    ActionChip(
                      label: const Text('🍽️ Restaurant'),
                      onPressed: () {
                        _textController.text =
                            'Store: KFC Dhanmondi\nItems: Chicken Bucket, Fries, Drinks\nTotal: BDT 890';
                        setState(() {});
                      },
                    ),
                    ActionChip(
                      label: const Text('⛽ Fuel'),
                      onPressed: () {
                        _textController.text =
                            'Station: Padma Oil\nItems: Octane 10L\nTotal: BDT 1,050';
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _loading || _textController.text.trim().isEmpty
                        ? null
                        : _parseReceipt,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('Parse & Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_parsed != null) ...[
          const SizedBox(height: 16),
          _ParsedTransactionCard(
            parsed: _parsed!,
            onSave: () => _saveParsed(context, _parsed!, forceExpense: true),
          ),
        ],
      ],
    );
  }

  Future<void> _parseReceipt() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final parsed = _parseReceiptLocally(_textController.text.trim());
      setState(() => _parsed = parsed);
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Could not parse receipt: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _parseReceiptLocally(String text) {
    final lower = text.toLowerCase();

    // Extract amount
    double amount = 0;
    final amountRegex = RegExp(r'(?:total|amount|sum|bdt|tk|taka)?\s*:?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
    // Find the line with highest number as total
    final lines = text.split('\n');
    for (final line in lines.reversed) {
      final match = amountRegex.firstMatch(line.trim());
      if (match != null) {
        final cleaned = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(cleaned);
        if (parsed != null && parsed > 0) {
          amount = parsed;
          break;
        }
      }
    }

    // If regex didn't catch from reversed lines, try harder
    if (amount == 0) {
      // Look for any number preceded by BDT, TK, Taka, Total
      final totalRegex = RegExp(r'(?:total|bdt|tk|taka|amount)[:\s]*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
      final match = totalRegex.firstMatch(text);
      if (match != null) {
        final cleaned = match.group(1)!.replaceAll(',', '');
        amount = double.tryParse(cleaned) ?? 0;
      }
    }

    // Extract store name
    String store = '';
    final storeRegex = RegExp(r'(?:store|shop|station|restaurant|cafe)[:\s]+(.+)', caseSensitive: false);
    final storeMatch = storeRegex.firstMatch(text);
    if (storeMatch != null) {
      store = storeMatch.group(1)!.trim();
    }

    // Determine category from items/store
    String category = 'shopping';
    if (lower.contains('restaurant') || lower.contains('cafe') || lower.contains('kfc') || lower.contains('pizza') || lower.contains('food') || lower.contains('meal')) {
      category = 'food';
    } else if (lower.contains('fuel') || lower.contains('petrol') || lower.contains('octane') || lower.contains('diesel') || lower.contains('gas station')) {
      category = 'transport';
    } else if (lower.contains('medicine') || lower.contains('pharmacy') || lower.contains('hospital') || lower.contains('clinic') || lower.contains('doctor')) {
      category = 'healthcare';
    } else if (lower.contains('electric') || lower.contains('gas bill') || lower.contains('water') || lower.contains('utility')) {
      category = 'utilities';
    } else if (lower.contains('grocery') || lower.contains('super') || lower.contains('mart') || lower.contains('rice') || lower.contains('vegetable')) {
      category = 'groceries';
    }

    return {
      'amount': amount,
      'category': category,
      'channel': 'cash',
      'description': store.isNotEmpty ? 'Purchase at $store' : 'Receipt item',
      'txn_date': DateTime.now().toIso8601String(),
    };
  }
}

class _EmergencyFundPanel extends StatefulWidget {
  const _EmergencyFundPanel();

  @override
  State<_EmergencyFundPanel> createState() => _EmergencyFundPanelState();
}

class _EmergencyFundPanelState extends State<_EmergencyFundPanel> {
  final _savingsController = TextEditingController();
  final _targetMonthsController = TextEditingController();
  final _monthlyContributionController = TextEditingController();
  bool _loadedSavedPlan = false;

  @override
  void initState() {
    super.initState();
    // Load saved plan after first frame so we can access context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedPlan();
    });
  }

  void _loadSavedPlan() {
    if (_loadedSavedPlan) return;
    final store = context.read<TransactionStore>();
    final plan = store.emergencyFundPlan;
    if (plan != null) {
      _savingsController.text = '${plan['current_savings'] ?? 0}';
      _targetMonthsController.text = '${plan['target_months'] ?? 6}';
      _monthlyContributionController.text = '${plan['monthly_contribution'] ?? 0}';
      _loadedSavedPlan = true;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _savingsController.dispose();
    _targetMonthsController.dispose();
    _monthlyContributionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TransactionStore>();
    final txns = store.transactions;
    final monthlyExpense = _averageMonthlyExpense(txns);
    final savings = double.tryParse(_savingsController.text) ?? 0;
    final targetMonths = double.tryParse(_targetMonthsController.text.isEmpty ? '6' : _targetMonthsController.text) ?? 6;
    final contribution =
        double.tryParse(_monthlyContributionController.text) ?? 0;
    final target = monthlyExpense * targetMonths;
    final gap = max(0.0, target - savings);
    final monthsToGoal = contribution > 0 ? (gap / contribution).ceil() : null;

    return _PanelScaffold(
      title: 'Emergency Fund Planner',
      children: [
        _MetricRow(
            label: 'Average monthly expense',
            value: 'BDT ${monthlyExpense.toStringAsFixed(0)}'),
        const SizedBox(height: 12),
        TextField(
          controller: _savingsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Current savings', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _targetMonthsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Target months of expenses',
              border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _monthlyContributionController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Monthly contribution', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
            value: target <= 0 ? 0 : (savings / target).clamp(0.0, 1.0)),
        const SizedBox(height: 12),
        _MetricRow(
            label: 'Target fund', value: 'BDT ${target.toStringAsFixed(0)}'),
        _MetricRow(
            label: 'Remaining gap', value: 'BDT ${gap.toStringAsFixed(0)}'),
        _MetricRow(
            label: 'Time to goal',
            value: monthsToGoal == null
                ? 'Add contribution'
                : '$monthsToGoal months'),
        const SizedBox(height: 12),
        if (store.emergencyFundPlan != null) ...[
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  const Text('Plan saved', style: TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await store.saveEmergencyFundPlan(
                        monthlyExpense: monthlyExpense,
                        currentSavings: savings,
                        targetMonths: targetMonths,
                        monthlyContribution: contribution,
                      );
                      if (!context.mounted) return;
                      _showSnack(context, 'Emergency fund plan updated.');
                    },
                    child: const Text('Update'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: () async {
            await store.saveEmergencyFundPlan(
                  monthlyExpense: monthlyExpense,
                  currentSavings: savings,
                  targetMonths: targetMonths,
                  monthlyContribution: contribution,
                );
            if (!context.mounted) return;
            _showSnack(context, 'Emergency fund plan saved.');
          },
          icon: const Icon(Icons.save),
          label: Text(store.emergencyFundPlan != null ? 'Update Plan' : 'Save Plan'),
        ),
      ],
    );
  }
}

class _DebtTrackerPanel extends StatefulWidget {
  const _DebtTrackerPanel();

  @override
  State<_DebtTrackerPanel> createState() => _DebtTrackerPanelState();
}

class _DebtTrackerPanelState extends State<_DebtTrackerPanel> {
  final _nameController = TextEditingController();
  final _principalController = TextEditingController();
  final _paidController = TextEditingController(text: '0');
  final _paymentController = TextEditingController();
  final _interestController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  bool _isLent = false;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    _principalController.dispose();
    _paidController.dispose();
    _paymentController.dispose();
    _interestController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debts = context.watch<TransactionStore>().debts;
    final totalRemaining = debts.fold<double>(0, (sum, d) => sum + d.remaining);

    return _PanelScaffold(
      title: 'Debt / Loan Tracker',
      children: [
        _MetricRow(
            label: 'Total remaining',
            value: 'BDT ${totalRemaining.toStringAsFixed(0)}'),
        const SizedBox(height: 12),
        TextField(
            controller: _nameController,
            decoration: const InputDecoration(
                labelText: 'Debt name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: TextField(
                    controller: _principalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Principal', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _paidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Paid', border: OutlineInputBorder()))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: TextField(
                    controller: _paymentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Monthly payment',
                        border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _interestController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Interest %',
                        border: OutlineInputBorder()))),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _isLent,
          onChanged: (value) => setState(() => _isLent = value),
          title: const Text('Money I lent to someone'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event),
          title: Text('Due ${_dueDate.toString().split(' ').first}'),
          trailing: const Icon(Icons.edit_calendar),
          onTap: _pickDate,
        ),
        TextField(
            controller: _noteController,
            decoration: const InputDecoration(
                labelText: 'Note', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: _saveDebt,
            icon: const Icon(Icons.add),
            label: const Text('Add Debt')),
        const SizedBox(height: 16),
        ...debts.map((debt) => Card(
              child: ListTile(
                leading:
                    Icon(debt.isLent ? Icons.call_made : Icons.call_received),
                title: Text(debt.name),
                subtitle: Text(
                    'Due ${debt.dueDate.toString().split(' ').first} • ${debt.interestRate.toStringAsFixed(1)}%'),
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('BDT ${debt.remaining.toStringAsFixed(0)}'),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => context
                          .read<TransactionStore>()
                          .deleteDebtById(debt.id),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _saveDebt() async {
    final name = _nameController.text.trim();
    final principal = double.tryParse(_principalController.text) ?? 0;
    if (name.isEmpty || principal <= 0) return;
    await context.read<TransactionStore>().addDebt(DebtEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          principal: principal,
          paid: double.tryParse(_paidController.text) ?? 0,
          interestRate: double.tryParse(_interestController.text) ?? 0,
          monthlyPayment: double.tryParse(_paymentController.text) ?? 0,
          dueDate: _dueDate,
          isLent: _isLent,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          createdAt: DateTime.now(),
        ));
    _nameController.clear();
    _principalController.clear();
    _paymentController.clear();
    _noteController.clear();
    if (!mounted) return;
    _showSnack(context, 'Debt saved.');
  }
}

class _CashflowCalendarPanel extends StatelessWidget {
  const _CashflowCalendarPanel();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TransactionStore>();
    final now = DateTime.now();
    final days =
        List.generate(30, (i) => DateTime(now.year, now.month, now.day + i));

    return _PanelScaffold(
      title: 'Cashflow Calendar',
      children: days
          .map((day) {
            final income = store.transactions
                .where((t) =>
                    _sameDay(t.date, day) && t.type == TransactionType.income)
                .fold<double>(0, (sum, t) => sum + t.amount);
            final expense = store.transactions
                .where((t) =>
                    _sameDay(t.date, day) && t.type == TransactionType.expense)
                .fold<double>(0, (sum, t) => sum + t.amount);
            final debtDue = store.debts
                .where((d) => _sameDay(d.dueDate, day))
                .fold<double>(0, (sum, d) => sum + d.monthlyPayment);
            final net = income - expense - debtDue;
            if (income == 0 && expense == 0 && debtDue == 0) {
              return const SizedBox.shrink();
            }
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${day.day}')),
                title: Text(day.toString().split(' ').first),
                subtitle: Text(
                    'Income BDT ${income.toStringAsFixed(0)} • Expense BDT ${(expense + debtDue).toStringAsFixed(0)}'),
                trailing: Text(
                  '${net >= 0 ? '+' : '-'}BDT ${net.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                      color: net >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ),
            );
          })
          .where((w) => w is! SizedBox)
          .toList(),
    );
  }
}

class _AssistantChatPanel extends StatefulWidget {
  const _AssistantChatPanel();

  @override
  State<_AssistantChatPanel> createState() => _AssistantChatPanelState();
}

class _AssistantChatPanelState extends State<_AssistantChatPanel> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(false,
        '👋 Hi! I can answer questions about your finances using your local data.\n\n'
        'Try asking:\n'
        '• "What\'s my total income?"\n'
        '• "How much did I spend?"\n'
        '• "What\'s my balance?"\n'
        '• "Show my top categories"\n'
        '• "How many transactions do I have?"'),
  ];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment:
                    msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 520),
                  decoration: BoxDecoration(
                    color: msg.isUser ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                        color: msg.isUser ? Colors.white : Colors.black87),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask about your money...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _loading ? null : _send,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final store = context.read<TransactionStore>();
    final txns = store.transactions;
    final income = txns
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = txns
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final debts = store.debts;
    final totalDebt = debts.fold<double>(0, (sum, d) => sum + d.remaining);

    setState(() {
      _messages.add(_ChatMessage(true, text));
      _controller.clear();
      _loading = true;
    });

    // Short delay to simulate thinking
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final reply = _generateLocalReply(text, income, expense, txns.length, totalDebt);
      setState(() => _messages.add(_ChatMessage(false, reply)));

      // Save chat locally via store
      await store.saveChatMessage(
        message: text,
        response: reply,
        panel: 'Assistant',
      );
    } catch (e) {
      setState(() => _messages.add(_ChatMessage(false, 'Something went wrong. Please try again.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _generateLocalReply(String query, double income, double expense, int txnCount, double totalDebt) {
    final store = context.read<TransactionStore>();
    final debts = store.debts;
    final debtsCount = debts.length;
    final lower = query.toLowerCase();
    final balance = income - expense;

    if (lower.contains('income') || lower.contains('earn') || lower.contains('received')) {
      return '💰 **Total Income**: BDT ${income.toStringAsFixed(2)}\n'
          'Across ${txnCount} transaction(s).';
    }
    if (lower.contains('expense') || lower.contains('spend') || lower.contains('spent') || lower.contains('cost')) {
      return '💸 **Total Expense**: BDT ${expense.toStringAsFixed(2)}\n'
          'Across ${txnCount} transaction(s).';
    }
    if (lower.contains('balance') || lower.contains('saving') || lower.contains('net') || lower.contains('left')) {
      return '📊 **Net Balance**: BDT ${balance.toStringAsFixed(2)}\n'
          '${balance >= 0 ? '✅ You\'re in positive territory!' : '⚠️ Your expenses exceed income.'}';
    }
    if (lower.contains('debt') || lower.contains('loan') || lower.contains('owe') || lower.contains('due')) {
      if (totalDebt > 0) {
        return '📋 **Total Debt Remaining**: BDT ${totalDebt.toStringAsFixed(2)}\n'
            'You have $debtsCount active debt(s). Keep working on paying them down!';
      } else {
        return '🎉 No debts recorded! Great financial discipline.';
      }
    }
    if (lower.contains('category') || lower.contains('top') || lower.contains('where')) {
      return '📂 **Categories**:\nYou can view detailed category breakdowns in the Reports tab.';
    }
    if (lower.contains('count') || lower.contains('how many') || lower.contains('transactions') || lower.contains('total')) {
      return '📝 **Transaction Count**: $txnCount\n'
          'Total Income: BDT ${income.toStringAsFixed(2)}\n'
          'Total Expense: BDT ${expense.toStringAsFixed(2)}';
    }
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return '👋 Hello! How can I help with your finances today?';
    }
    if (lower.contains('help') || lower.contains('what can')) {
      return '💡 **You can ask me:**\n'
          '• "What\'s my total income?"\n'
          '• "How much did I spend?"\n'
          '• "What\'s my balance?"\n'
          '• "Show my debts"\n'
          '• "How many transactions?"';
    }

    // Default response using available data
    return '📊 **From your data:**\n'
        '• Income: BDT ${income.toStringAsFixed(2)}\n'
        '• Expense: BDT ${expense.toStringAsFixed(2)}\n'
        '• Balance: BDT ${balance.toStringAsFixed(2)}\n'
        '• Active debts: $debtsCount\n\n'
        'Type "help" to see what I can answer.';
  }
}

class _ParsedTransactionCard extends StatelessWidget {
  const _ParsedTransactionCard({required this.parsed, required this.onSave});

  final Map<String, dynamic> parsed;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricRow(
                label: 'Amount',
                value: 'BDT ${(parsed['amount'] ?? 0).toString()}'),
            _MetricRow(
                label: 'Category',
                value: '${parsed['category'] ?? 'shopping'}'),
            _MetricRow(
                label: 'Channel', value: '${parsed['channel'] ?? 'cash'}'),
            _MetricRow(
                label: 'Description', value: '${parsed['description'] ?? ''}'),
            const SizedBox(height: 8),
            FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('Save Transaction')),
          ],
        ),
      ),
    );
  }
}

class _PanelScaffold extends StatelessWidget {
  const _PanelScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;

  _ChatMessage(this.isUser, this.text);
}

Future<void> _saveParsed(
  BuildContext context,
  Map<String, dynamic> parsed, {
  bool forceExpense = false,
}) async {
  final store = context.read<TransactionStore>();
  final uid = store.userId;
  if (uid == null) return;
  final category = '${parsed['category'] ?? 'shopping'}';
  final channel = _channelFrom('${parsed['channel'] ?? 'cash'}');
  final date =
      DateTime.tryParse('${parsed['txn_date'] ?? ''}') ?? DateTime.now();
  final type = forceExpense || category != 'salary'
      ? TransactionType.expense
      : TransactionType.income;
  await store.addTransaction(Transaction(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    userId: uid,
    date: date,
    amount: (parsed['amount'] ?? 0).toDouble(),
    type: type,
    category: category,
    channel: channel,
    description: parsed['description'],
    createdAt: DateTime.now(),
  ));
  if (!context.mounted) return;
  _showSnack(context, 'Transaction saved.');
}

TransactionChannel _channelFrom(String value) {
  final normalized = value.toLowerCase();
  for (final channel in TransactionChannel.values) {
    if (channel.name == normalized) return channel;
  }
  return TransactionChannel.cash;
}

double _averageMonthlyExpense(List<Transaction> txns) {
  final now = DateTime.now();
  var total = 0.0;
  var months = 0;
  for (var i = 0; i < 3; i++) {
    final month = DateTime(now.year, now.month - i, 1);
    final expense = txns
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .fold<double>(0, (sum, t) => sum + t.amount);
    if (expense > 0) {
      total += expense;
      months++;
    }
  }
  return months == 0 ? 0 : total / months;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}