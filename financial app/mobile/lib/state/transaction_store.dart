import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart' hide Transaction;
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/transaction_model.dart';
import '../models/debt_model.dart';

class TransactionStore extends ChangeNotifier {
  TransactionStore({bool firebaseEnabled = true})
      : _firebaseEnabled = firebaseEnabled;

  final bool _firebaseEnabled;
  final List<Transaction> _transactions = [];
  final List<DebtEntry> _debts = [];
  StreamSubscription<DatabaseEvent>? _txnSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _debtSubscription;
  String? _userId;

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<DebtEntry> get debts => List.unmodifiable(_debts);
  String? get userId => _userId;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  DatabaseReference get _rtdb => FirebaseDatabase.instance.ref();

  Future<void> bindToUser(String uid) async {
    if (!_firebaseEnabled) {
      _userId = uid;
      notifyListeners();
      return;
    }

    if (_userId == uid && _txnSubscription != null) {
      return;
    }

    await _txnSubscription?.cancel();
    await _debtSubscription?.cancel();
    _userId = uid;
    _transactions.clear();
    _debts.clear();
    notifyListeners();

    _listenToTransactionStream(uid);
    _listenToDebtStream(uid);

    try {
      await _saveFcmTokenForUser();
    } catch (e) {
      debugPrint('Firebase FCM token save skipped: $e');
    }
  }

  Future<void> unbindUser() async {
    await _txnSubscription?.cancel();
    await _debtSubscription?.cancel();
    _txnSubscription = null;
    _debtSubscription = null;
    _userId = null;
    _transactions.clear();
    _debts.clear();
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    if (_userId == null) return;

    // CRITICAL: Always add to the local list FIRST.
    // This ensures the transaction appears instantly in Records, Charts,
    // Reports, and all other UI panels regardless of Firebase connectivity.
    _transactions.insert(0, transaction);
    notifyListeners();

    if (!_firebaseEnabled) {
      return;
    }

    // Realtime Database write in the background
    final docId = transaction.id.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : transaction.id;
    final ref =
        _rtdb.child('users').child(_userId!).child('transactions').child(docId);

    final payload = transaction.toMap()
      ..['id'] = docId
      ..['user_id'] = _userId
      ..['txn_date'] = transaction.date.toIso8601String()
      ..['created_at'] = transaction.createdAt.toIso8601String();

    try {
      await ref.set(payload);
    } catch (e) {
      debugPrint('addTransaction Realtime DB write failed: $e');
      // Attempt Firestore fallback so data isn't lost if Realtime DB is unreachable
      try {
        final fsPayload = Map<String, dynamic>.from(transaction.toMap())
          ..['id'] = docId
          ..['user_id'] = _userId
          ..['txn_date'] = Timestamp.fromDate(transaction.date)
          ..['created_at'] = Timestamp.fromDate(transaction.createdAt);
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('transactions')
            .doc(docId)
            .set(fsPayload);
        debugPrint('addTransaction wrote to Firestore as fallback');
      } catch (fsErr) {
        debugPrint('addTransaction Firestore fallback also failed: $fsErr');
      }
    }

    // Save category insights independently
    try {
      await _saveCategoryInsights();
    } catch (e) {
      debugPrint('saveCategoryInsights after addTransaction failed: $e');
    }
  }

  Future<void> deleteTransactionById(String id) async {
    if (_userId == null) return;
    if (!_firebaseEnabled) {
      _transactions.removeWhere((txn) => txn.id == id);
      notifyListeners();
      return;
    }
    try {
      await _rtdb
          .child('users')
          .child(_userId!)
          .child('transactions')
          .child(id)
          .remove();
      // CRITICAL: Also remove from local list immediately
      _transactions.removeWhere((txn) => txn.id == id);
      notifyListeners();
      await _saveCategoryInsights();
    } catch (e) {
      debugPrint('deleteTransaction Realtime DB write skipped: $e');
      // Try deleting from Firestore as a fallback
      try {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('transactions')
            .doc(id)
            .delete();
        _transactions.removeWhere((txn) => txn.id == id);
        notifyListeners();
        await _saveCategoryInsights();
        debugPrint(
            'deleteTransaction removed document from Firestore fallback');
      } catch (fsErr) {
        debugPrint('deleteTransaction Firestore fallback failed: $fsErr');
      }
    }
  }

  Future<void> updateTransaction(Transaction updated) async {
    if (_userId == null) return;
    if (!_firebaseEnabled) {
      final index = _transactions.indexWhere((txn) => txn.id == updated.id);
      if (index >= 0) {
        _transactions[index] = updated;
        notifyListeners();
      }
      return;
    }
    final payload = updated.toMap()
      ..['id'] = updated.id
      ..['user_id'] = _userId
      ..['txn_date'] = updated.date.toIso8601String()
      ..['created_at'] = updated.createdAt.toIso8601String();

    try {
      await _rtdb
          .child('users')
          .child(_userId!)
          .child('transactions')
          .child(updated.id)
          .set(payload);

      // CRITICAL: Also update local list immediately
      final index = _transactions.indexWhere((txn) => txn.id == updated.id);
      if (index >= 0) {
        _transactions[index] = updated;
        notifyListeners();
      }

      await _saveCategoryInsights();
    } catch (e) {
      debugPrint('updateTransaction Realtime DB write skipped: $e');
      // Firestore fallback
      try {
        final fsPayload = updated.toMap()
          ..['id'] = updated.id
          ..['user_id'] = _userId
          ..['txn_date'] = Timestamp.fromDate(updated.date)
          ..['created_at'] = Timestamp.fromDate(updated.createdAt);
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('transactions')
            .doc(updated.id)
            .set(fsPayload, SetOptions(merge: true));
        final index = _transactions.indexWhere((txn) => txn.id == updated.id);
        if (index >= 0) {
          _transactions[index] = updated;
          notifyListeners();
        }
        await _saveCategoryInsights();
        debugPrint('updateTransaction wrote to Firestore as fallback');
      } catch (fsErr) {
        debugPrint('updateTransaction Firestore fallback failed: $fsErr');
      }
    }
  }

  Future<void> saveBudgetPlan({
    required String monthKey,
    required double targetSavingsRate,
    required double targetExpenseBudget,
    required double projectedExpense,
    required double safeDailySpend,
  }) async {
    if (_userId == null) return;
    if (!_firebaseEnabled) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('monthly_plans')
          .doc(monthKey)
          .set({
        'month_key': monthKey,
        'target_savings_rate': targetSavingsRate,
        'target_expense_budget': targetExpenseBudget,
        'projected_expense': projectedExpense,
        'safe_daily_spend': safeDailySpend,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveBudgetPlan Firestore write skipped: $e');
    }
  }

  Future<void> saveWhatIfScenario({
    required String scenario,
    required String category,
    required double reductionPercent,
    required double projectedSavings,
    required double endOfMonthCash,
    required double riskScore,
    bool isBestPlan = false,
  }) async {
    if (_userId == null) return;
    if (!_firebaseEnabled) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('what_if_history')
          .add({
        'scenario': scenario,
        'category': category,
        'reduction_percent': reductionPercent,
        'projected_savings': projectedSavings,
        'end_of_month_cash': endOfMonthCash,
        'risk_score': riskScore,
        'is_best_plan': isBestPlan,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('saveWhatIfScenario Firestore write skipped: $e');
    }
  }

  Future<void> saveHealthSnapshot({
    required String weekKey,
    required double score,
    required double savingsRateScore,
    required double stabilityScore,
    required double concentrationScore,
    required double runwayScore,
  }) async {
    if (_userId == null) return;
    if (!_firebaseEnabled) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('health_scores')
          .doc(weekKey)
          .set({
        'week_key': weekKey,
        'score': score,
        'savings_rate_score': savingsRateScore,
        'stability_score': stabilityScore,
        'concentration_score': concentrationScore,
        'runway_score': runwayScore,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveHealthSnapshot Firestore write skipped: $e');
    }
  }

  Future<void> saveOverspendingAlert({
    required String alertMessage,
    required int? daysToCross,
    required List<String> fixes,
  }) async {
    if (_userId == null) return;
    if (!_firebaseEnabled) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('alerts')
          .add({
        'type': 'overspending',
        'message': alertMessage,
        'days_to_cross': daysToCross,
        'fixes': fixes,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('saveOverspendingAlert Firestore write skipped: $e');
    }
  }

  // Emergency fund plan data stored locally
  Map<String, dynamic>? _emergencyFundPlan;
  Map<String, dynamic>? get emergencyFundPlan => _emergencyFundPlan;

  Future<void> saveEmergencyFundPlan({
    required double monthlyExpense,
    required double currentSavings,
    required double targetMonths,
    required double monthlyContribution,
  }) async {
    if (_userId == null) return;
    
    // Always save locally immediately
    _emergencyFundPlan = {
      'monthly_expense': monthlyExpense,
      'current_savings': currentSavings,
      'target_months': targetMonths,
      'target_amount': monthlyExpense * targetMonths,
      'monthly_contribution': monthlyContribution,
      'updated_at': DateTime.now().toIso8601String(),
    };
    notifyListeners();

    if (!_firebaseEnabled) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('emergency_fund')
          .doc('active')
          .set({
        'monthly_expense': monthlyExpense,
        'current_savings': currentSavings,
        'target_months': targetMonths,
        'target_amount': monthlyExpense * targetMonths,
        'monthly_contribution': monthlyContribution,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveEmergencyFundPlan Firestore write skipped: $e');
    }
  }

  Future<void> addDebt(DebtEntry debt) async {
    if (_userId == null) return;
    
    // Always add to local list immediately for instant UI update
    _debts.add(debt);
    _debts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    notifyListeners();

    if (!_firebaseEnabled) return;
    
    final ref = _firestore
        .collection('users')
        .doc(_userId)
        .collection('debts')
        .doc(debt.id.isEmpty
            ? DateTime.now().microsecondsSinceEpoch.toString()
            : debt.id);
    try {
      final docId = ref.id;
      await ref.set(debt.toMap()..['id'] = docId);
    } catch (e) {
      debugPrint('addDebt Firestore write skipped: $e');
    }
  }

  Future<void> deleteDebtById(String id) async {
    if (_userId == null) return;
    
    // Always remove from local list immediately
    _debts.removeWhere((debt) => debt.id == id);
    notifyListeners();

    if (!_firebaseEnabled) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('debts')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('deleteDebt Firestore write skipped: $e');
    }
  }

  void _listenToTransactionStream(String uid) {
    _txnSubscription = _rtdb
        .child('users')
        .child(uid)
        .child('transactions')
        .orderByChild('txn_date')
        .limitToLast(500)
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      final rtdbIds = <String>{};
      final rtdbTxns = <Transaction>[];

      if (data is Map) {
        for (final entry in data.entries) {
          final key = entry.key.toString();
          final value = Map<String, dynamic>.from(entry.value as Map);
          value['id'] = value['id'] ?? key;
          value['user_id'] = value['user_id'] ?? uid;
          rtdbIds.add(key);
          rtdbTxns.add(Transaction.fromMap(value));
        }
      }

      // CRITICAL: Remove only transactions that already exist in Realtime DB,
      // keeping locally-added transactions that haven't been synced yet.
      _transactions.removeWhere((txn) => rtdbIds.contains(txn.id));

      // Add all Realtime DB-sourced transactions
      _transactions.addAll(rtdbTxns);

      // Sort by date descending for consistent ordering
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
    }, onError: (error) {
      debugPrint('Realtime DB transaction stream error: $error');
      _txnSubscription = null;
      Future.delayed(const Duration(seconds: 3), () {
        if (_userId == uid && _txnSubscription == null) {
          _listenToTransactionStream(uid);
        }
      });
    });
  }

  void _listenToDebtStream(String uid) {
    _debtSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('debts')
        .orderBy('due_date')
        .snapshots()
        .listen((snapshot) {
      final firestoreIds = <String>{};
      final firestoreDebts = <DebtEntry>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = data['id'] ?? doc.id;
        firestoreIds.add(doc.id);
        firestoreDebts.add(DebtEntry.fromMap(data));
      }
      // Keep locally-added debts that haven't synced yet, replace the rest with Firestore data
      _debts.removeWhere((debt) => firestoreIds.contains(debt.id));
      _debts.addAll(firestoreDebts);
      _debts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      notifyListeners();
    }, onError: (error, stackTrace) {
      debugPrint('Firestore debt stream error: $error');
      _debtSubscription = null;
      Future.delayed(const Duration(seconds: 3), () {
        if (_userId == uid && _debtSubscription == null) {
          _listenToDebtStream(uid);
        }
      });
    });
  }

  /// Force a one-time fetch of transactions from Realtime Database.
  Future<void> refreshTransactions() async {
    if (_userId == null || !_firebaseEnabled) return;
    try {
      final snapshot = await _rtdb
          .child('users')
          .child(_userId!)
          .child('transactions')
          .orderByChild('txn_date')
          .limitToLast(500)
          .once();

      final data = snapshot.snapshot.value;
      _transactions.clear();

      if (data is Map) {
        for (final entry in data.entries) {
          final key = entry.key.toString();
          final value = Map<String, dynamic>.from(entry.value as Map);
          value['id'] = value['id'] ?? key;
          value['user_id'] = value['user_id'] ?? _userId;
          _transactions.add(Transaction.fromMap(value));
        }
      }

      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      debugPrint(
          'refreshTransactions: loaded ${_transactions.length} transactions');
    } catch (e) {
      debugPrint('refreshTransactions failed: $e');
    }
  }

  Future<void> _saveCategoryInsights() async {
    if (_userId == null) return;
    if (!_firebaseEnabled) return;
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final expenseTxns = _transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month);

    final totals = <String, double>{};
    for (final txn in expenseTxns) {
      totals[txn.category] = (totals[txn.category] ?? 0) + txn.amount;
    }

    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = ranked
        .take(5)
        .map((e) => {'category': e.key, 'amount': e.value})
        .toList();

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('category_insights')
          .doc(monthKey)
          .set({
        'month_key': monthKey,
        'top_categories': topCategories,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveCategoryInsights Firestore write skipped: $e');
    }
  }

  Future<void> _saveFcmTokenForUser() async {
    if (_userId == null) return;
    if (!_firebaseEnabled) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    try {
      await _firestore.collection('users').doc(_userId).set({
        'fcm_token': token,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveFcmToken Firestore write skipped: $e');
    }
  }

  Future<void> saveChatMessage({
    required String message,
    required String response,
    required String panel,
  }) async {
    if (_userId == null) return;
    if (!_firebaseEnabled) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chat_history')
          .add({
        'message': message,
        'response': response,
        'panel': panel,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('saveChatMessage Firestore write skipped: $e');
    }
  }

  @override
  void dispose() {
    _txnSubscription?.cancel();
    _debtSubscription?.cancel();
    super.dispose();
  }
}
