import 'package:cloud_firestore/cloud_firestore.dart';

class DebtEntry {
  final String id;
  final String name;
  final double principal;
  final double paid;
  final double interestRate;
  final double monthlyPayment;
  final DateTime dueDate;
  final bool isLent;
  final String? note;
  final DateTime createdAt;

  DebtEntry({
    required this.id,
    required this.name,
    required this.principal,
    required this.paid,
    required this.interestRate,
    required this.monthlyPayment,
    required this.dueDate,
    required this.isLent,
    this.note,
    required this.createdAt,
  });

  double get remaining => (principal - paid).clamp(0, double.infinity);

  factory DebtEntry.fromMap(Map<String, dynamic> map) {
    return DebtEntry(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Debt',
      principal: (map['principal'] ?? 0).toDouble(),
      paid: (map['paid'] ?? 0).toDouble(),
      interestRate: (map['interest_rate'] ?? 0).toDouble(),
      monthlyPayment: (map['monthly_payment'] ?? 0).toDouble(),
      dueDate: _parseDate(map['due_date']),
      isLent: map['is_lent'] ?? false,
      note: map['note'],
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'principal': principal,
      'paid': paid,
      'interest_rate': interestRate,
      'monthly_payment': monthlyPayment,
      'due_date': Timestamp.fromDate(dueDate),
      'is_lent': isLent,
      'note': note,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
