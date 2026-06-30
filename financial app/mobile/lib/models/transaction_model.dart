import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionChannel { cash, bkash, nagad, rocket, bank }

enum TransactionType { expense, income }

class Transaction {
  final String id;
  final String userId;
  final DateTime date;
  final double amount;
  final TransactionType type;
  final String category;
  final TransactionChannel channel;
  final String? description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.channel,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      date: _parseDate(map['txn_date']),
      amount: (map['amount'] ?? 0).toDouble(),
      type: TransactionType.values.byName(map['type'] ?? 'expense'),
      category: map['category'] ?? 'other',
      channel: TransactionChannel.values.byName(map['channel'] ?? 'cash'),
      description: map['description'],
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'txn_date': date.toIso8601String(),
      'amount': amount,
      'type': type.name,
      'category': category,
      'channel': channel.name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
