import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../state/transaction_store.dart';

class AddTab extends StatefulWidget {
  const AddTab({Key? key}) : super(key: key);

  @override
  State<AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<AddTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'expense';
  String _selectedCategory = 'shopping';
  TransactionChannel _selectedChannel = TransactionChannel.cash;

  final List<String> _expenseCategories = [
    'shopping',
    'food',
    'phone',
    'entertainment',
    'education',
    'beauty',
    'sports',
    'social',
    'transportation',
    'clothing',
    'car',
  ];

  final List<String> _incomeCategories = [
    'salary',
    'investments',
    'part-time',
    'bonus',
    'others',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Transaction',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Transaction Type Selector
                Text(
                  'Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Expense'),
                        selected: _transactionType == 'expense',
                        onSelected: (_) {
                          setState(() {
                            _transactionType = 'expense';
                            _selectedCategory = _expenseCategories.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Income'),
                        selected: _transactionType == 'income',
                        onSelected: (_) {
                          setState(() {
                            _transactionType = 'income';
                            _selectedCategory = _incomeCategories.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (৳)',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Amount is required';
                    }
                    if (double.tryParse(value!) == null) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: (_transactionType == 'expense'
                          ? _expenseCategories
                          : _incomeCategories)
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value ??
                        (_transactionType == 'expense'
                            ? _expenseCategories.first
                            : _incomeCategories.first));
                  },
                ),
                const SizedBox(height: 16),

                // Channel Dropdown
                DropdownButtonFormField<TransactionChannel>(
                  initialValue: _selectedChannel,
                  decoration: InputDecoration(
                    labelText: 'Payment Channel',
                    prefixIcon: const Icon(Icons.payment),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: TransactionChannel.values
                      .map((channel) => DropdownMenuItem(
                            value: channel,
                            child: Text(channel.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() =>
                        _selectedChannel = value ?? TransactionChannel.cash);
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _submitForm();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Save Transaction'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final store = context.read<TransactionStore>();
      final currentUserId = store.userId;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUserId,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        type: _transactionType == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        category: _selectedCategory,
        channel: _selectedChannel,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );
      await store.addTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_transactionType == 'income' ? 'Income' : 'Expense'} saved successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _transactionType = 'expense';
        _selectedCategory = _expenseCategories.first;
        _selectedChannel = TransactionChannel.cash;
        _selectedDate = DateTime.now();
      });
    }
  }
}
