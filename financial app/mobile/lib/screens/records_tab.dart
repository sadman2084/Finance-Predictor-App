import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../state/transaction_store.dart';

class RecordsTab extends StatelessWidget {
  const RecordsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionStore>().transactions;

    return Scaffold(
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                final isIncome = txn.type == TransactionType.income;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    onTap: () => _showDetails(context, txn),
                    leading: CircleAvatar(
                      backgroundColor: _getCategoryColor(txn.category),
                      child: Icon(
                        _getCategoryIcon(txn.category),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      txn.category.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isIncome ? 'Income' : 'Expense'} • ${txn.description ?? 'No description'}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📅 ${txn.date.toString().split(' ')[0]} • ${txn.channel.name}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'}৳${txn.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) {
                            if (value == 'details') {
                              _showDetails(context, txn);
                            } else if (value == 'edit') {
                              _showEditDialog(context, txn);
                            } else if (value == 'delete') {
                              _deleteTransaction(context, txn);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: 'details', child: Text('Details')),
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    titleAlignment: ListTileTitleAlignment.top,
                    horizontalTitleGap: 12,
                    minVerticalPadding: 8,
                    visualDensity: const VisualDensity(vertical: 1),
                    // per-item actions
                    subtitleTextStyle: Theme.of(context).textTheme.bodyMedium,
                    selected: false,
                    selectedTileColor: Colors.transparent,
                    dense: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    mouseCursor: SystemMouseCursors.click,
                  ),
                );
              },
            ),
    );
  }

  void _showDetails(BuildContext context, Transaction txn) {
    final isIncome = txn.type == TransactionType.income;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction Details',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _detailRow('Type', isIncome ? 'Income' : 'Expense'),
              _detailRow('Category', txn.category),
              _detailRow('Amount', '৳${txn.amount.toStringAsFixed(0)}'),
              _detailRow('Date', txn.date.toString().split(' ')[0]),
              _detailRow('Channel', txn.channel.name),
              _detailRow('Description', txn.description ?? 'No description'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDialog(context, txn);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteTransaction(context, txn);
                      },
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.red),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Transaction txn) {
    final amountController =
        TextEditingController(text: txn.amount.toStringAsFixed(0));
    final descController = TextEditingController(text: txn.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final parsed = double.tryParse(amountController.text.trim());
                if (parsed == null) return;
                final updated = Transaction(
                  id: txn.id,
                  userId: txn.userId,
                  date: txn.date,
                  amount: parsed,
                  type: txn.type,
                  category: txn.category,
                  channel: txn.channel,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  createdAt: txn.createdAt,
                );
                await context
                    .read<TransactionStore>()
                    .updateTransaction(updated);
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTransaction(BuildContext context, Transaction txn) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await context
                    .read<TransactionStore>()
                    .deleteTransactionById(txn.id);
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    const colors = {
      // Expense categories
      'shopping': Colors.pink,
      'food': Colors.orange,
      'phone': Colors.cyan,
      'entertainment': Colors.purple,
      'education': Colors.blue,
      'beauty': Colors.red,
      'sports': Colors.green,
      'social': Colors.amber,
      'transportation': Colors.indigo,
      'clothing': Colors.brown,
      'car': Colors.blueGrey,
      // Income categories
      'salary': Colors.green,
      'investments': Colors.teal,
      'part-time': Colors.lightBlue,
      'bonus': Colors.lime,
      'others': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      // Expense categories
      'shopping': Icons.shopping_bag,
      'food': Icons.restaurant,
      'phone': Icons.phone,
      'entertainment': Icons.movie,
      'education': Icons.school,
      'beauty': Icons.spa,
      'sports': Icons.sports_football,
      'social': Icons.people,
      'transportation': Icons.directions_car,
      'clothing': Icons.checkroom,
      'car': Icons.directions_car,
      // Income categories
      'salary': Icons.account_balance_wallet,
      'investments': Icons.trending_up,
      'part-time': Icons.work,
      'bonus': Icons.card_giftcard,
      'others': Icons.attach_money,
    };
    return icons[category] ?? Icons.attach_money;
  }
}
