import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionBillingCycle { daily, weekly, monthly, annually }
enum SubscriptionStatus { active, cancelled, paused }

enum PaymentMethod {
  bkash,
  nagad,
  bankCard,
  cash,
  rocket,
  bank;

  String get displayName {
    switch (this) {
      case PaymentMethod.bkash:
        return 'bKash';
      case PaymentMethod.nagad:
        return 'Nagad';
      case PaymentMethod.bankCard:
        return 'Bank Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.rocket:
        return 'Rocket';
      case PaymentMethod.bank:
        return 'Bank';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.bkash:
        return 'bkash';
      case PaymentMethod.nagad:
        return 'nagad';
      case PaymentMethod.bankCard:
        return 'bank_card';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.rocket:
        return 'rocket';
      case PaymentMethod.bank:
        return 'bank';
    }
  }
}

class Subscription {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String currency;
  final SubscriptionBillingCycle billingCycle;
  final DateTime startDate;
  final DateTime nextBillingDate;
  final DateTime? lastBilledDate;
  final String category;
  final String channel;
  final SubscriptionStatus status;
  final bool autoRenew;
  final PaymentMethod paymentMethod;
  final String? paymentDetails; // e.g., bKash/Nagad number, card last 4 digits
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    this.currency = 'BDT',
    required this.billingCycle,
    required this.startDate,
    required this.nextBillingDate,
    this.lastBilledDate,
    required this.category,
    required this.channel,
    required this.status,
    required this.autoRenew,
    this.paymentMethod = PaymentMethod.bkash,
    this.paymentDetails,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 3,
    required this.createdAt,
    required this.updatedAt,
  });

  double get monthlyCost {
    switch (billingCycle) {
      case SubscriptionBillingCycle.daily:
        return amount * 30;
      case SubscriptionBillingCycle.weekly:
        return amount * 4.33;
      case SubscriptionBillingCycle.monthly:
        return amount;
      case SubscriptionBillingCycle.annually:
        return amount / 12;
    }
  }

  bool get isDueSoon {
    final daysUntilBilling = nextBillingDate.difference(DateTime.now()).inDays;
    return daysUntilBilling >= 0 && daysUntilBilling <= reminderDaysBefore;
  }

  bool get isOverdue {
    return nextBillingDate.isBefore(DateTime.now()) && status == SubscriptionStatus.active;
  }

  int get daysUntilNextBilling {
    return nextBillingDate.difference(DateTime.now()).inDays;
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'BDT',
      billingCycle: SubscriptionBillingCycle.values.byName(map['billing_cycle'] ?? 'monthly'),
      startDate: _parseDate(map['start_date']),
      nextBillingDate: _parseDate(map['next_billing_date']),
      lastBilledDate: _parseDateNullable(map['last_billed_date']),
      category: map['category'] ?? 'other',
      channel: map['channel'] ?? 'cash',
      status: SubscriptionStatus.values.byName(map['status'] ?? 'active'),
      autoRenew: map['auto_renew'] ?? true,
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == map['payment_method'],
              orElse: () => PaymentMethod.bkash,
            )
          : PaymentMethod.bkash,
      paymentDetails: map['payment_details'],
      reminderEnabled: map['reminder_enabled'] ?? true,
      reminderDaysBefore: map['reminder_days_before'] ?? 3,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'currency': currency,
      'billing_cycle': billingCycle.name,
      'start_date': startDate.toIso8601String(),
      'next_billing_date': nextBillingDate.toIso8601String(),
      'last_billed_date': lastBilledDate?.toIso8601String(),
      'category': category,
      'channel': channel,
      'status': status.name,
      'auto_renew': autoRenew,
      'payment_method': paymentMethod.name,
      'payment_details': paymentDetails,
      'reminder_enabled': reminderEnabled,
      'reminder_days_before': reminderDaysBefore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    String? currency,
    SubscriptionBillingCycle? billingCycle,
    DateTime? startDate,
    DateTime? nextBillingDate,
    DateTime? lastBilledDate,
    String? category,
    String? channel,
    SubscriptionStatus? status,
    bool? autoRenew,
    PaymentMethod? paymentMethod,
    String? paymentDetails,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      startDate: startDate ?? this.startDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      lastBilledDate: lastBilledDate ?? this.lastBilledDate,
      category: category ?? this.category,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      autoRenew: autoRenew ?? this.autoRenew,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    return _parseDate(value);
  }
}