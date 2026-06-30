import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/subscription_model.dart';

class SubscriptionStore extends ChangeNotifier {
  SubscriptionStore({bool firebaseEnabled = true})
      : _firebaseEnabled = firebaseEnabled;

  final bool _firebaseEnabled;
  final List<Subscription> _subscriptions = [];
  StreamSubscription<DatabaseEvent>? _subscriptionStream;
  String? _userId;

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  String? get userId => _userId;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  DatabaseReference get _rtdb => FirebaseDatabase.instance.ref();

  // ──────────────────────────────────────────────
  // Analytics & Computed Properties
  // ──────────────────────────────────────────────

  double get totalMonthlyCost {
    return _subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .fold<double>(0, (total, s) => total + s.monthlyCost);
  }

  double get totalYearlyCost => totalMonthlyCost * 12;

  double get amountDueThisMonth {
    final now = DateTime.now();
    return _subscriptions
        .where((s) =>
            s.status == SubscriptionStatus.active &&
            s.nextBillingDate.month == now.month &&
            s.nextBillingDate.year == now.year)
        .fold<double>(0, (total, s) => total + s.amount);
  }

  List<Subscription> getDueSoonSubscriptions({int days = 7}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    return _subscriptions.where((s) {
      if (s.status != SubscriptionStatus.active) return false;
      return s.nextBillingDate.isAfter(now) &&
          s.nextBillingDate.isBefore(cutoff);
    }).toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
  }

  List<Subscription> get autoRenewSubscriptions {
    return _subscriptions
        .where((s) => s.status == SubscriptionStatus.active && s.autoRenew)
        .toList();
  }

  List<Subscription> get overdueSubscriptions {
    final now = DateTime.now();
    return _subscriptions
        .where((s) =>
            s.status == SubscriptionStatus.active &&
            s.nextBillingDate.isBefore(now))
        .toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
  }

  Map<String, List<Subscription>> get subscriptionsByCategory {
    final map = <String, List<Subscription>>{};
    for (final sub in _subscriptions) {
      if (sub.status != SubscriptionStatus.active) continue;
      map.putIfAbsent(sub.category, () => []);
      map[sub.category]!.add(sub);
    }
    return map;
  }

  Map<String, double> get categoryMonthlySpending {
    final map = <String, double>{};
    for (final sub in _subscriptions) {
      if (sub.status != SubscriptionStatus.active) continue;
      map.update(sub.category, (v) => v + sub.monthlyCost,
          ifAbsent: () => sub.monthlyCost);
    }
    return map;
  }

  Map<PaymentMethod, List<Subscription>> get subscriptionsByPaymentMethod {
    final map = <PaymentMethod, List<Subscription>>{};
    for (final sub in _subscriptions) {
      if (sub.status != SubscriptionStatus.active) continue;
      map.putIfAbsent(sub.paymentMethod, () => []);
      map[sub.paymentMethod]!.add(sub);
    }
    return map;
  }

  Map<PaymentMethod, double> get paymentMethodTotals {
    final map = <PaymentMethod, double>{};
    for (final sub in _subscriptions) {
      if (sub.status != SubscriptionStatus.active) continue;
      map.update(sub.paymentMethod, (v) => v + sub.monthlyCost,
          ifAbsent: () => sub.monthlyCost);
    }
    return map;
  }

  double get healthScore {
    if (_subscriptions.isEmpty) return 100;
    double score = 100;
    final overdueCount = overdueSubscriptions.length;
    score -= (overdueCount * 20).toDouble();
    final nonAutoRenew = _subscriptions
        .where((s) => s.status == SubscriptionStatus.active && !s.autoRenew)
        .length;
    score -= (nonAutoRenew * 10).toDouble();
    final methodCount = subscriptionsByPaymentMethod.length;
    score += (methodCount * 5).clamp(0, 15).toDouble();
    final activeCount =
        _subscriptions.where((s) => s.status == SubscriptionStatus.active).length;
    if (activeCount > 5) {
      score -= ((activeCount - 5) * 5).toDouble();
    }
    return score.clamp(0, 100);
  }

  List<CancelRecommendation> get cancelRecommendations {
    final recommendations = <CancelRecommendation>[];
    final now = DateTime.now();
    for (final sub in _subscriptions) {
      if (sub.status != SubscriptionStatus.active) continue;
      final reasons = <String>[];
      double urgencyScore = 0;
      if (sub.isOverdue) {
        reasons.add('Payment overdue by ${sub.daysUntilNextBilling.abs()} days');
        urgencyScore += 30;
      }
      if (sub.lastBilledDate != null) {
        final monthsSinceLastBilled =
            now.difference(sub.lastBilledDate!).inDays / 30;
        if (monthsSinceLastBilled > 3) {
          reasons.add('Not billed in ${monthsSinceLastBilled.toStringAsFixed(1)} months');
          urgencyScore += 20;
        }
      }
      if (totalMonthlyCost > 0) {
        final costRatio = sub.monthlyCost / totalMonthlyCost;
        if (costRatio > 0.3) {
          reasons.add('Costs ${(costRatio * 100).toStringAsFixed(0)}% of total');
          urgencyScore += 25;
        }
      }
      final nonEssential = ['entertainment', 'beauty', 'sports', 'social'];
      if (nonEssential.contains(sub.category)) {
        urgencyScore += 10;
        if (reasons.isEmpty) reasons.add('Non-essential category (${sub.category})');
      }
      if (reasons.isNotEmpty) {
        recommendations.add(CancelRecommendation(
            subscription: sub, reasons: reasons, urgencyScore: urgencyScore));
      }
    }
    recommendations.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
    return recommendations;
  }

  List<UpcomingPayment> get upcomingPayments {
    final now = DateTime.now();
    final payments = <UpcomingPayment>[];
    for (final sub in _subscriptions) {
      if (sub.status != SubscriptionStatus.active) continue;
      var nextDate = sub.nextBillingDate;
      for (int i = 0; i < 6; i++) {
        if (nextDate.isBefore(now.subtract(const Duration(days: 1)))) {
          nextDate = _nextBillingDate(sub, nextDate);
          continue;
        }
        payments.add(UpcomingPayment(
          subscription: sub,
          dueDate: nextDate,
          amount: sub.amount,
          isPaid: sub.lastBilledDate != null &&
              sub.lastBilledDate!.month == nextDate.month &&
              sub.lastBilledDate!.year == nextDate.year,
        ));
        nextDate = _nextBillingDate(sub, nextDate);
      }
    }
    payments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return payments;
  }

  DateTime _nextBillingDate(Subscription sub, DateTime currentDate) {
    switch (sub.billingCycle) {
      case SubscriptionBillingCycle.daily:
        return currentDate.add(const Duration(days: 1));
      case SubscriptionBillingCycle.weekly:
        return currentDate.add(const Duration(days: 7));
      case SubscriptionBillingCycle.monthly:
        return DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
      case SubscriptionBillingCycle.annually:
        return DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
    }
  }

  MonthlySummary get monthlySummary {
    final now = DateTime.now();
    final thisMonthSubs = _subscriptions.where((s) {
      if (s.status != SubscriptionStatus.active) return false;
      return s.nextBillingDate.month == now.month &&
          s.nextBillingDate.year == now.year;
    }).toList();
    return MonthlySummary(
      totalDue: thisMonthSubs.fold<double>(0, (total, sub) => total + sub.amount),
      count: thisMonthSubs.length,
      paidCount: thisMonthSubs
          .where((s) =>
              s.lastBilledDate != null &&
              s.lastBilledDate!.month == now.month &&
              s.lastBilledDate!.year == now.year)
          .length,
      upcomingCount: getDueSoonSubscriptions(days: 7).length,
      healthScore: healthScore,
    );
  }

  // ──────────────────────────────────────────────
  // Firebase Operations (Realtime DB - same as transactions)
  // ──────────────────────────────────────────────

  Future<void> bindToUser(String uid) async {
    if (!_firebaseEnabled) {
      _userId = uid;
      notifyListeners();
      return;
    }
    if (_userId == uid && _subscriptionStream != null) {
      return;
    }
    await _subscriptionStream?.cancel();
    _userId = uid;
    _subscriptions.clear();
    notifyListeners();
    _listenToSubscriptionStream(uid);
  }

  Future<void> unbindUser() async {
    await _subscriptionStream?.cancel();
    _subscriptionStream = null;
    _userId = null;
    _subscriptions.clear();
    notifyListeners();
  }

  Future<void> addSubscription(Subscription subscription) async {
    if (_userId == null) return;

    // Add to local list FIRST for instant UI update
    _subscriptions.insert(0, subscription);
    notifyListeners();

    if (!_firebaseEnabled) return;

    final docId = subscription.id.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : subscription.id;

    // Write to Realtime Database (same as transactions)
    final ref =
        _rtdb.child('users').child(_userId!).child('subscriptions').child(docId);

    final payload = subscription.toMap()
      ..['id'] = docId
      ..['user_id'] = _userId
      ..['start_date'] = subscription.startDate.toIso8601String()
      ..['next_billing_date'] = subscription.nextBillingDate.toIso8601String()
      ..['last_billed_date'] = subscription.lastBilledDate?.toIso8601String()
      ..['created_at'] = subscription.createdAt.toIso8601String()
      ..['updated_at'] = subscription.updatedAt.toIso8601String();

    try {
      await ref.set(payload);
      debugPrint('addSubscription saved to Realtime DB: $docId');
    } catch (e) {
      debugPrint('addSubscription Realtime DB write failed: $e');
      // Firestore fallback
      try {
        final fsPayload = Map<String, dynamic>.from(subscription.toMap())
          ..['id'] = docId
          ..['user_id'] = _userId
          ..['start_date'] = Timestamp.fromDate(subscription.startDate)
          ..['next_billing_date'] = Timestamp.fromDate(subscription.nextBillingDate)
          ..['last_billed_date'] = subscription.lastBilledDate != null
              ? Timestamp.fromDate(subscription.lastBilledDate!)
              : null
          ..['created_at'] = Timestamp.fromDate(subscription.createdAt)
          ..['updated_at'] = Timestamp.fromDate(subscription.updatedAt);
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('subscriptions')
            .doc(docId)
            .set(fsPayload);
        debugPrint('addSubscription wrote to Firestore as fallback');
      } catch (fsErr) {
        debugPrint('addSubscription Firestore fallback also failed: $fsErr');
      }
    }
  }

  Future<void> deleteSubscriptionById(String id) async {
    if (_userId == null) return;
    if (!_firebaseEnabled) {
      _subscriptions.removeWhere((sub) => sub.id == id);
      notifyListeners();
      return;
    }
    // Delete from Realtime DB
    try {
      await _rtdb
          .child('users')
          .child(_userId!)
          .child('subscriptions')
          .child(id)
          .remove();
    } catch (e) {
      debugPrint('deleteSubscription Realtime DB failed: $e');
      // Firestore fallback
      try {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('subscriptions')
            .doc(id)
            .delete();
      } catch (fsErr) {
        debugPrint('deleteSubscription Firestore fallback failed: $fsErr');
      }
    }
    _subscriptions.removeWhere((sub) => sub.id == id);
    notifyListeners();
  }

  Future<void> updateSubscription(Subscription updated) async {
    if (_userId == null) return;
    if (!_firebaseEnabled) {
      final index = _subscriptions.indexWhere((sub) => sub.id == updated.id);
      if (index >= 0) {
        _subscriptions[index] = updated;
        notifyListeners();
      }
      return;
    }
    // Update Realtime DB
    final payload = updated.toMap()
      ..['id'] = updated.id
      ..['user_id'] = _userId
      ..['start_date'] = updated.startDate.toIso8601String()
      ..['next_billing_date'] = updated.nextBillingDate.toIso8601String()
      ..['last_billed_date'] = updated.lastBilledDate?.toIso8601String()
      ..['created_at'] = updated.createdAt.toIso8601String()
      ..['updated_at'] = updated.updatedAt.toIso8601String();

    try {
      await _rtdb
          .child('users')
          .child(_userId!)
          .child('subscriptions')
          .child(updated.id)
          .set(payload);
    } catch (e) {
      debugPrint('updateSubscription Realtime DB failed: $e');
      // Firestore fallback
      try {
        final fsPayload = Map<String, dynamic>.from(updated.toMap())
          ..['id'] = updated.id
          ..['user_id'] = _userId
          ..['start_date'] = Timestamp.fromDate(updated.startDate)
          ..['next_billing_date'] = Timestamp.fromDate(updated.nextBillingDate)
          ..['last_billed_date'] = updated.lastBilledDate != null
              ? Timestamp.fromDate(updated.lastBilledDate!)
              : null
          ..['created_at'] = Timestamp.fromDate(updated.createdAt)
          ..['updated_at'] = Timestamp.fromDate(updated.updatedAt);
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('subscriptions')
            .doc(updated.id)
            .set(fsPayload, SetOptions(merge: true));
      } catch (fsErr) {
        debugPrint('updateSubscription Firestore fallback failed: $fsErr');
      }
    }
    final index = _subscriptions.indexWhere((sub) => sub.id == updated.id);
    if (index >= 0) {
      _subscriptions[index] = updated;
      notifyListeners();
    }
  }

  void _listenToSubscriptionStream(String uid) {
    _subscriptionStream = _rtdb
        .child('users')
        .child(uid)
        .child('subscriptions')
        .onValue
        .listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data == null) {
        _subscriptions.clear();
        notifyListeners();
        return;
      }

      final subs = <Subscription>[];
      if (data is Map<Object?, Object?>) {
        for (final entry in data.entries) {
          if (entry.value is Map) {
            final map = Map<String, dynamic>.from(entry.value as Map);
            map['id'] = entry.key.toString();
            map['user_id'] = uid;
            subs.add(Subscription.fromMap(map));
          }
        }
      }

      _subscriptions
        ..clear()
        ..addAll(subs);
      notifyListeners();
    }, onError: (error, stackTrace) {
      debugPrint('Realtime DB subscription stream error: $error');
      _subscriptionStream = null;
      Future.delayed(const Duration(seconds: 3), () {
        if (_userId == uid && _subscriptionStream == null) {
          _listenToSubscriptionStream(uid);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}

class CancelRecommendation {
  final Subscription subscription;
  final List<String> reasons;
  final double urgencyScore;
  CancelRecommendation({
    required this.subscription,
    required this.reasons,
    required this.urgencyScore,
  });
}

class UpcomingPayment {
  final Subscription subscription;
  final DateTime dueDate;
  final double amount;
  final bool isPaid;
  UpcomingPayment({
    required this.subscription,
    required this.dueDate,
    required this.amount,
    this.isPaid = false,
  });
}

class MonthlySummary {
  final double totalDue;
  final int count;
  final int paidCount;
  final int upcomingCount;
  final double healthScore;
  MonthlySummary({
    required this.totalDue,
    required this.count,
    required this.paidCount,
    required this.upcomingCount,
    required this.healthScore,
  });
}