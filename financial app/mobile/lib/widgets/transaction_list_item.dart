import 'package:flutter/material.dart';

class TransactionListItem extends StatelessWidget {
  final String category;
  final String description;
  final double amount;
  final String channel;
  final IconData icon;
  final Color color;

  const TransactionListItem({
    Key? key,
    required this.category,
    required this.description,
    required this.amount,
    required this.channel,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          category.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '৳${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            Text(channel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
