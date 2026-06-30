import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/subscription_model.dart';
import '../state/subscription_store.dart';

class PaymentScreen extends StatefulWidget {
  final Subscription subscription;
  final double amount;

  const PaymentScreen({
    Key? key,
    required this.subscription,
    required this.amount,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _paymentSuccess = false;
  String? _transactionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final method = widget.subscription.paymentMethod;
    final currencyFormat =
        NumberFormat.currency(locale: 'en_US', symbol: '৳ ');

    if (_paymentSuccess) {
      return _buildSuccessScreen(context, theme, currencyFormat);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pay with ${method.displayName}'),
        backgroundColor: _getMethodColor(method),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Method Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getMethodColor(method).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getMethodColor(method).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getMethodIcon(method),
                      size: 56,
                      color: _getMethodColor(method),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      method.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getMethodColor(method),
                      ),
                    ),
                    if (widget.subscription.paymentDetails != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Account: ${widget.subscription.paymentDetails}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Subscription Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subscription Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold)),
                      const Divider(),
                      _buildDetailRow('Service', widget.subscription.name),
                      _buildDetailRow('Category',
                          widget.subscription.category.capitalizeFirst()),
                      _buildDetailRow(
                        'Billing Cycle',
                        widget.subscription.billingCycle.name
                            .capitalizeFirst(),
                      ),
                      _buildDetailRow(
                        'Next Billing',
                        DateFormat.yMMMd()
                            .format(widget.subscription.nextBillingDate),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount to Pay
              Card(
                color: _getMethodColor(method).withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount to Pay',
                          style: theme.textTheme.titleMedium),
                      Text(
                        currencyFormat.format(widget.amount),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getMethodColor(method),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (widget.subscription.autoRenew)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.autorenew,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-renewal is enabled.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              if (method == PaymentMethod.bkash ||
                  method == PaymentMethod.nagad)
                _buildMobileBankingInstructions(
                    context, method, currencyFormat),

              if (method == PaymentMethod.bankCard)
                _buildCardInstructions(context),

              if (method == PaymentMethod.cash)
                _buildCashInstructions(context),

              const SizedBox(height: 24),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processPayment,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Pay ${currencyFormat.format(widget.amount)}',
                    style: const TextStyle(fontSize: 17),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getMethodColor(method),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                      _isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMobileBankingInstructions(BuildContext context,
      PaymentMethod method, NumberFormat currencyFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: _getMethodColor(method), size: 20),
                const SizedBox(width: 8),
                Text('Payment Instructions',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '1. Open your ${method.displayName} app\n'
              '2. Select "Send Money" or "Payment"\n'
              '3. Send ${currencyFormat.format(widget.amount)} to:\n'
              '   ${widget.subscription.paymentDetails ?? "Merchant Account"}\n'
              '4. Enter your PIN to confirm\n'
              '5. Copy the Transaction ID\n'
              '6. Paste it below and tap "Pay"',
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Transaction ID',
                hintText: 'Enter ${method.displayName} TrxID',
                prefixIcon: const Icon(Icons.receipt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => _transactionId = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInstructions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF1565C0), size: 20),
                const SizedBox(width: 8),
                Text('Card Payment',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: 'XXXX XXXX XXXX XXXX',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 19,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      hintText: 'MM/YY',
                      prefixIcon: const Icon(Icons.calendar_month),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'Name on card',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashInstructions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.money, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pay in cash to the service provider. '
                'Mark as paid once you have made the payment.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(
      BuildContext context, ThemeData theme, NumberFormat currencyFormat) {
    final method = widget.subscription.paymentMethod;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Successful'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'Payment Successful!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your subscription to ${widget.subscription.name} '
                'has been activated.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(_getMethodIcon(method),
                        size: 32, color: _getMethodColor(method)),
                    const SizedBox(height: 8),
                    Text(
                      'Paid via ${method.displayName}',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700),
                    ),
                    if (_transactionId != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'TrxID: $_transactionId',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(widget.amount),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _onBackToSubscriptions,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Subscriptions',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBackToSubscriptions() {
    // Pop back to subscriptions list
    Navigator.of(context).pop(true);
  }

  Future<void> _processPayment() async {
    // Validate transaction ID for mobile banking
    final method = widget.subscription.paymentMethod;
    if ((method == PaymentMethod.bkash ||
            method == PaymentMethod.nagad) &&
        (_transactionId == null || _transactionId!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please enter the ${method.displayName} Transaction ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 1));

    // Save to Firestore
    try {
      if (!mounted) return;
      final store = context.read<SubscriptionStore>();
      await store.addSubscription(widget.subscription);
    } catch (e) {
      debugPrint('Error saving subscription: $e');
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _paymentSuccess = true;
    });
  }

  Color _getMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
        return const Color(0xFFE2136E);
      case PaymentMethod.nagad:
        return const Color(0xFFED1C24);
      case PaymentMethod.bankCard:
        return const Color(0xFF1565C0);
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.rocket:
        return const Color(0xFFCC2244);
      case PaymentMethod.bank:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
        return Icons.phone_android;
      case PaymentMethod.nagad:
        return Icons.smartphone;
      case PaymentMethod.bankCard:
        return Icons.credit_card;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.rocket:
        return Icons.rocket_launch;
      case PaymentMethod.bank:
        return Icons.account_balance;
    }
  }
}

extension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}