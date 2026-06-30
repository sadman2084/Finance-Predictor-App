import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subscription_model.dart';
import '../state/subscription_store.dart';
import 'payment_screen.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final Subscription? existingSubscription;

  const AddSubscriptionScreen({Key? key, this.existingSubscription})
      : super(key: key);

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentDetailsController = TextEditingController();

  // Predefined services with their amounts
  static const Map<String, Map<String, dynamic>> _predefinedServices = {
    'Netflix (Mobile)': {'amounts': [149, 299], 'category': 'entertainment'},
    'Netflix (Basic)': {'amounts': [349, 699], 'category': 'entertainment'},
    'Netflix (Standard)': {'amounts': [549, 1099], 'category': 'entertainment'},
    'Netflix (Premium)': {'amounts': [749, 1499], 'category': 'entertainment'},
    'YouTube Premium': {'amounts': [149, 299], 'category': 'entertainment'},
    'Spotify Premium': {'amounts': [149, 179], 'category': 'entertainment'},
    'Amazon Prime Video': {'amounts': [299, 599], 'category': 'entertainment'},
    'Disney+ Hotstar': {'amounts': [299, 699, 1499], 'category': 'entertainment'},
    'Apple Music': {'amounts': [149, 299], 'category': 'entertainment'},
    'Apple TV+': {'amounts': [349, 699], 'category': 'entertainment'},
    'Google One (100GB)': {'amounts': [69, 139], 'category': 'software'},
    'Google One (200GB)': {'amounts': [139, 279], 'category': 'software'},
    'Google One (2TB)': {'amounts': [699, 1399], 'category': 'software'},
    'iCloud (50GB)': {'amounts': [99, 199], 'category': 'software'},
    'iCloud (200GB)': {'amounts': [299, 599], 'category': 'software'},
    'iCloud (2TB)': {'amounts': [899, 1799], 'category': 'software'},
    'Microsoft 365 Personal': {'amounts': [699, 5799], 'category': 'software'},
    'Microsoft 365 Family': {'amounts': [999, 7999], 'category': 'software'},
    'ChatGPT Plus': {'amounts': [2100], 'category': 'software'},
    'Midjourney': {'amounts': [1200, 2400], 'category': 'software'},
    'Canva Pro': {'amounts': [699, 7199], 'category': 'software'},
    'Adobe Photoshop': {'amounts': [2499, 12699], 'category': 'software'},
    'Adobe Premiere Pro': {'amounts': [2499, 12699], 'category': 'software'},
    'Grammarly Premium': {'amounts': [1299, 2999], 'category': 'software'},
    'NordVPN': {'amounts': [499, 2999], 'category': 'software'},
    'Gym Membership (Basic)': {'amounts': [1500, 3000], 'category': 'sports'},
    'Gym Membership (Premium)': {'amounts': [3000, 6000], 'category': 'sports'},
    'Gym Membership (Annual)': {'amounts': [15000, 30000], 'category': 'sports'},
    'Gym Trainer (Personal)': {'amounts': [5000, 10000], 'category': 'sports'},
    'Phone (Grameenphone)': {'amounts': [199, 499, 999], 'category': 'phone'},
    'Phone (Robi)': {'amounts': [199, 499, 999], 'category': 'phone'},
    'Phone (Banglalink)': {'amounts': [199, 499, 999], 'category': 'phone'},
    'Internet (BTCL)': {'amounts': [999, 1499, 1999], 'category': 'internet'},
    'Internet (Link3)': {'amounts': [999, 1499, 1999], 'category': 'internet'},
    'Internet (AmberIT)': {'amounts': [999, 1499, 1999], 'category': 'internet'},
    'Cable TV': {'amounts': [500, 1500, 3000], 'category': 'entertainment'},
    'Water Bill': {'amounts': [300, 1000], 'category': 'other'},
    'Electricity Bill': {'amounts': [500, 3000], 'category': 'other'},
    'Gas Bill': {'amounts': [300, 1000], 'category': 'other'},
    'Insurance (Life)': {'amounts': [3000, 10000], 'category': 'insurance'},
    'Insurance (Health)': {'amounts': [5000, 15000], 'category': 'health'},
    'Insurance (Car)': {'amounts': [5000, 20000], 'category': 'car'},
    'Tuition (School)': {'amounts': [3000, 10000], 'category': 'education'},
    'Tuition (College)': {'amounts': [5000, 15000], 'category': 'education'},
    'Tuition (University)': {'amounts': [10000, 50000], 'category': 'education'},
    'Other Service': {'amounts': [100, 500, 1000, 5000, 10000], 'category': 'other'},
  };

  String? _selectedService;
  double? _selectedAmount;
  String _selectedCategory = 'entertainment';

  DateTime _startDate = DateTime.now();
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  SubscriptionBillingCycle _selectedBillingCycle =
      SubscriptionBillingCycle.monthly;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.bkash;
  bool _autoRenew = true;
  bool _reminderEnabled = true;
  int _reminderDaysBefore = 3;

  @override
  void initState() {
    super.initState();
    if (widget.existingSubscription != null) {
      final sub = widget.existingSubscription!;
      // Find matching service or use custom
      _selectedService = sub.name;
      _selectedAmount = sub.amount;
      _paymentDetailsController.text = sub.paymentDetails ?? '';
      _startDate = sub.startDate;
      _nextBillingDate = sub.nextBillingDate;
      _selectedCategory = sub.category;
      _selectedBillingCycle = sub.billingCycle;
      _selectedPaymentMethod = sub.paymentMethod;
      _autoRenew = sub.autoRenew;
      _reminderEnabled = sub.reminderEnabled;
      _reminderDaysBefore = sub.reminderDaysBefore;
    }
  }

  @override
  void dispose() {
    _paymentDetailsController.dispose();
    super.dispose();
  }

  List<String> get _serviceNames => _predefinedServices.keys.toList();

  List<double> get _availableAmounts {
    if (_selectedService == null) return [];
    final serviceData = _predefinedServices[_selectedService!];
    if (serviceData == null) return [];
    return List<double>.from(serviceData['amounts'] as List);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSubscription != null
            ? 'Edit Subscription'
            : 'Add Subscription'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Service Name (Dropdown) ──
                Text('Select Service',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: InputDecoration(
                    hintText: 'Choose a service...',
                    prefixIcon: const Icon(Icons.subscriptions),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  isExpanded: true,
                  items: _serviceNames
                      .map((service) => DropdownMenuItem(
                            value: service,
                            child: Text(service,
                                style: const TextStyle(fontSize: 15)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedService = value;
                      _selectedAmount = null;
                      if (value != null) {
                        final data = _predefinedServices[value]!;
                        _selectedCategory = data['category'] as String;
                      }
                    });
                  },
                  validator: (v) =>
                      v == null ? 'Please select a service' : null,
                ),
                const SizedBox(height: 20),

                // ── Amount (from predefined, selectable) ──
                if (_selectedService != null) ...[
                  Text('Select Amount (৳)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildAmountSelector(),
                  const SizedBox(height: 20),
                ],

                // ── Billing Cycle ──
                Text('Billing Cycle',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<SubscriptionBillingCycle>(
                  value: _selectedBillingCycle,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.repeat),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: SubscriptionBillingCycle.values
                      .map((cycle) => DropdownMenuItem(
                            value: cycle,
                            child: Text(cycle.name.capitalizeFirst()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(
                      () => _selectedBillingCycle = v ?? _selectedBillingCycle),
                ),
                const SizedBox(height: 20),

                // ── Payment Method ──
                Text('Payment Method',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildPaymentMethodSelector(),
                const SizedBox(height: 16),

                // ── Payment Details ──
                if (_selectedPaymentMethod == PaymentMethod.bkash ||
                    _selectedPaymentMethod == PaymentMethod.nagad ||
                    _selectedPaymentMethod == PaymentMethod.bankCard)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPaymentDetailsLabel(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _paymentDetailsController,
                        decoration: InputDecoration(
                          hintText: _getPaymentDetailsHint(),
                          prefixIcon: const Icon(Icons.info_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // ── Start Date ──
                Text('Start Date',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickDate(context, true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    child: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Next Billing Date ──
                Text('Next Billing Date',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickDate(context, false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.event),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    child: Text(
                      '${_nextBillingDate.day}/${_nextBillingDate.month}/${_nextBillingDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Auto Renew ──
                SwitchListTile(
                  title: const Text('Auto Renew'),
                  subtitle: const Text('Automatically renew subscription'),
                  value: _autoRenew,
                  onChanged: (v) => setState(() => _autoRenew = v),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Reminder ──
                SwitchListTile(
                  title: const Text('Enable Reminder'),
                  subtitle: const Text('Get notified before billing date'),
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                if (_reminderEnabled) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Remind me'),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            initialValue: _reminderDaysBefore.toString(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            onChanged: (v) {
                              final days = int.tryParse(v);
                              if (days != null) {
                                setState(() =>
                                    _reminderDaysBefore = days.clamp(1, 30));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('days before'),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Submit Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: Icon(widget.existingSubscription != null
                        ? Icons.save
                        : Icons.add_circle),
                    label: Text(widget.existingSubscription != null
                        ? 'Update Subscription'
                        : 'Proceed to Payment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountSelector() {
    final amounts = _availableAmounts;
    if (amounts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amounts.map((amount) {
        final isSelected = _selectedAmount == amount;
        return ChoiceChip(
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '৳ ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : null,
                fontSize: 16,
              ),
            ),
          ),
          selected: isSelected,
          selectedColor: Colors.blue,
          backgroundColor: Colors.grey.shade100,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedAmount = amount);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final methods = [
      PaymentMethod.bkash,
      PaymentMethod.nagad,
      PaymentMethod.bankCard,
      PaymentMethod.cash,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: methods.map((method) {
        final isSelected = _selectedPaymentMethod == method;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPaymentIcon(method),
                size: 18,
                color: isSelected ? Colors.white : null,
              ),
              const SizedBox(width: 6),
              Text(method.displayName),
            ],
          ),
          selected: isSelected,
          selectedColor: _getPaymentColor(method),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedPaymentMethod = method);
            }
          },
        );
      }).toList(),
    );
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
        return Icons.phone_android;
      case PaymentMethod.nagad:
        return Icons.smartphone;
      case PaymentMethod.bankCard:
        return Icons.credit_card;
      case PaymentMethod.cash:
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
        return const Color(0xFFE2136E);
      case PaymentMethod.nagad:
        return const Color(0xFFED1C24);
      case PaymentMethod.bankCard:
        return const Color(0xFF1565C0);
      case PaymentMethod.cash:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getPaymentDetailsLabel() {
    switch (_selectedPaymentMethod) {
      case PaymentMethod.bkash:
        return 'bKash Account Number';
      case PaymentMethod.nagad:
        return 'Nagad Account Number';
      case PaymentMethod.bankCard:
        return 'Card Last 4 Digits';
      default:
        return 'Payment Details';
    }
  }

  String _getPaymentDetailsHint() {
    switch (_selectedPaymentMethod) {
      case PaymentMethod.bkash:
        return 'e.g., 01XXXXXXXXX';
      case PaymentMethod.nagad:
        return 'e.g., 01XXXXXXXXX';
      case PaymentMethod.bankCard:
        return 'e.g., 1234';
      default:
        return 'Optional';
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _nextBillingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _nextBillingDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final store = context.read<SubscriptionStore>();
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

    final now = DateTime.now();
    final subscription = Subscription(
      id: widget.existingSubscription?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      userId: currentUserId,
      name: _selectedService ?? 'Subscription',
      amount: _selectedAmount!,
      billingCycle: _selectedBillingCycle,
      startDate: _startDate,
      nextBillingDate: _nextBillingDate,
      category: _selectedCategory,
      channel: 'subscription',
      status: SubscriptionStatus.active,
      autoRenew: _autoRenew,
      paymentMethod: _selectedPaymentMethod,
      paymentDetails: _paymentDetailsController.text.trim().isEmpty
          ? null
          : _paymentDetailsController.text.trim(),
      reminderEnabled: _reminderEnabled,
      reminderDaysBefore: _reminderDaysBefore,
      createdAt: widget.existingSubscription?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.existingSubscription != null) {
      await store.updateSubscription(subscription);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription updated!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      return;
    }

    // Navigate to payment screen
    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          subscription: subscription,
          amount: _selectedAmount!,
        ),
      ),
    );

    // After coming back from payment, always pop back to subscriptions
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

extension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}