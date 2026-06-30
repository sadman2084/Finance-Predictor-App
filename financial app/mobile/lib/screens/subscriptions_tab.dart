import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/subscription_model.dart';
import '../state/subscription_store.dart';
import '../widgets/empty_content_prompt.dart';
import 'add_subscription_screen.dart';

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key});

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionStore>(
      builder: (context, store, child) {
        return Scaffold(
          appBar: store.subscriptions.isEmpty
              ? null
              : AppBar(
                  title: const Text('Subscriptions'),
                  automaticallyImplyLeading: false,
                  elevation: 0,
                ),
          body: store.subscriptions.isEmpty
              ? Center(
                  child: EmptyContentPrompt(
                    title: 'No Subscriptions Yet',
                    message:
                        'Add your subscriptions to track recurring expenses.',
                    icon: Icons.subscriptions_outlined,
                    actionLabel: 'Add Subscription',
                    onAction: _openAddSubscription,
                  ),
                )
              : Column(
                  children: [
                    _buildHealthBanner(store),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(icon: Icon(Icons.list), text: 'All'),
                        Tab(icon: Icon(Icons.summarize), text: 'Summary'),
                        Tab(icon: Icon(Icons.health_and_safety),
                            text: 'Health'),
                        Tab(icon: Icon(Icons.calendar_month),
                            text: 'Calendar'),
                        Tab(icon: Icon(Icons.payment), text: 'Payments'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _AllSubscriptionsTab(store: store),
                          _MonthlySummaryTab(store: store),
                          _HealthAndCancelTab(store: store),
                          _UpcomingCalendarTab(store: store),
                          _PaymentMethodsTab(store: store),
                        ],
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddSubscription,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _openAddSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()),
    );
  }

  Widget _buildHealthBanner(SubscriptionStore store) {
    final score = store.healthScore;
    Color c = Colors.green;
    if (score < 60) c = Colors.orange;
    if (score < 40) c = Colors.red;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: c, size: 20),
          const SizedBox(width: 8),
          Text('Health: ${score.toStringAsFixed(0)}/100',
              style: TextStyle(fontWeight: FontWeight.w600, color: c)),
          const Spacer(),
          Text('${store.subscriptions.length} subs',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ── TAB 1 ──
class _AllSubscriptionsTab extends StatelessWidget {
  final SubscriptionStore store;
  const _AllSubscriptionsTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final subs = store.subscriptions;
    if (subs.isEmpty) {
      return const Center(child: Text('No subscriptions'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: subs.length,
      itemBuilder: (_, i) => _SubCard(
        sub: subs[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  AddSubscriptionScreen(existingSubscription: subs[i])),
        ),
        onDelete: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete'),
              content: Text('Delete "${subs[i].name}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete')),
              ],
            ),
          );
          if (ok == true) {
            store.deleteSubscriptionById(subs[i].id);
          }
        },
      ),
    );
  }
}

class _SubCard extends StatelessWidget {
  final Subscription sub;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const _SubCard(
      {required this.sub, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cf = NumberFormat.currency(locale: 'en_US', symbol: '৳ ');
    final isDue = sub.isDueSoon && sub.status == SubscriptionStatus.active;
    final isOver = sub.isOverdue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isOver
            ? BorderSide(color: Colors.red.shade300)
            : isDue
                ? BorderSide(color: Colors.orange.shade300)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _color(sub.paymentMethod).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icon(sub.paymentMethod),
                  color: _color(sub.paymentMethod), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Row(children: [
                      Text(sub.category.capitalizeFirst(),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 6),
                      Text(sub.billingCycle.name.capitalizeFirst(),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      if (sub.autoRenew) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.autorenew, size: 14, color: Colors.green.shade400),
                      ],
                    ]),
                    Row(children: [
                      Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(DateFormat.yMMMd().format(sub.nextBillingDate),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ]),
                  ]),
            ),
            Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(cf.format(sub.amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent)),
                  if (isOver)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text('Overdue',
                          style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                    )
                  else if (isDue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text('${sub.daysUntilNextBilling}d',
                          style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                    ),
                  if (onDelete != null)
                    InkWell(
                      onTap: onDelete,
                      child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                    ),
                ]),
          ]),
        ),
      ),
    );
  }

  IconData _icon(PaymentMethod m) {
    switch (m) {
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

  Color _color(PaymentMethod m) {
    switch (m) {
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
}

// ── TAB 2 ──
class _MonthlySummaryTab extends StatelessWidget {
  final SubscriptionStore store;
  const _MonthlySummaryTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final cf = NumberFormat.currency(locale: 'en_US', symbol: '৳ ');
    final active = store.subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .length;
    if (active == 0) return const Center(child: Text('No active subscriptions'));

    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _card('Monthly', cf.format(store.totalMonthlyCost), Icons.money_off, Colors.red),
            const SizedBox(width: 8),
            _card('Yearly', cf.format(store.totalYearlyCost), Icons.calendar_month, Colors.orange),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _card('Active', '$active', Icons.check_circle, Colors.green),
            const SizedBox(width: 8),
            _card('Due', cf.format(store.amountDueThisMonth), Icons.payment, Colors.blue),
          ]),
          const SizedBox(height: 12),
          ...store.categoryMonthlySpending.entries.map((e) {
            final pct = store.totalMonthlyCost > 0
                ? (e.value / store.totalMonthlyCost * 100)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(e.key.capitalizeFirst(), style: const TextStyle(fontSize: 13)),
                  Text('${cf.format(e.value)} (${pct.toStringAsFixed(0)}%)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ]),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: store.totalMonthlyCost > 0 ? e.value / store.totalMonthlyCost : 0,
                    backgroundColor: Colors.grey.shade200,
                    minHeight: 5,
                  ),
                ),
              ]),
            );
          }),
        ]);
  }

  Widget _card(String t, String v, IconData ic, Color c) {
    return Expanded(
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Row(children: [
            Icon(ic, color: c, size: 16),
            const SizedBox(width: 4),
            Text(t, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ]),
          const SizedBox(height: 4),
          Text(v,
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c)),
        ]),
      )),
    );
  }
}

// ── TAB 3 ──
class _HealthAndCancelTab extends StatelessWidget {
  final SubscriptionStore store;
  const _HealthAndCancelTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final recs = store.cancelRecommendations;
    final cf = NumberFormat.currency(locale: 'en_US', symbol: '৳ ');
    final score = store.healthScore;

    if (store.subscriptions.where((s) => s.status == SubscriptionStatus.active).isEmpty) {
      return const Center(child: Text('No active subscriptions'));
    }

    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(fit: StackFit.expand, children: [
                CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 60 ? Colors.green : Colors.orange)),
                Center(
                    child: Text('${score.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: score >= 60 ? Colors.green : Colors.orange))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          if (recs.isEmpty)
            const Card(
                child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.thumb_up_alt, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('All subscriptions look good!', style: TextStyle(fontSize: 14))),
              ]),
            ))
          else
            ...recs.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text(r.subscription.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Text(cf.format(r.subscription.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ]),
                    ...r.reasons.take(2).map((reason) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          const Text('• ', style: TextStyle(color: Colors.red)),
                          Expanded(child: Text(reason, style: const TextStyle(fontSize: 11))),
                        ]))),
                  ]),
                ))),
        ]);
  }
}

// ── TAB 4 ──
class _UpcomingCalendarTab extends StatelessWidget {
  final SubscriptionStore store;
  const _UpcomingCalendarTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final payments = store.upcomingPayments;
    final cf = NumberFormat.currency(locale: 'en_US', symbol: '৳ ');
    if (payments.isEmpty) return const Center(child: Text('No upcoming payments'));

    final grouped = <String, List<UpcomingPayment>>{};
    for (final p in payments) {
      final key = DateFormat('MMMM yyyy').format(p.dueDate);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(p);
    }

    return ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((e) {
          final total = e.value.fold(0.0, (s, p) => s + p.amount);
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(cf.format(total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ]),
            ),
            ...e.value.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 3),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(radius: 12, backgroundColor: p.isPaid ? Colors.green : Colors.blue, child: Icon(p.isPaid ? Icons.check : Icons.event, size: 12, color: Colors.white)),
                  title: Text(p.subscription.name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(DateFormat.yMMMd().format(p.dueDate), style: const TextStyle(fontSize: 11)),
                  trailing: Text(cf.format(p.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ))),
            const Divider(),
          ]);
        }).toList());
  }
}

// ── TAB 5 ──
class _PaymentMethodsTab extends StatelessWidget {
  final SubscriptionStore store;
  const _PaymentMethodsTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final totals = store.paymentMethodTotals;
    final cf = NumberFormat.currency(locale: 'en_US', symbol: '৳ ');
    if (totals.isEmpty) return const Center(child: Text('No payment methods'));

    return ListView(
        padding: const EdgeInsets.all(16),
        children: totals.entries.map((e) {
          final subs = store.subscriptionsByPaymentMethod[e.key] ?? [];
          return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    Row(children: [
                      Icon(_icon(e.key), color: _color(e.key), size: 24),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      Text(cf.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                            value: store.totalMonthlyCost > 0 ? e.value / store.totalMonthlyCost : 0,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(_color(e.key)),
                            minHeight: 4)),
                    ...subs.map((s) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          const Icon(Icons.circle, size: 5, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(s.name, style: const TextStyle(fontSize: 11))),
                          Text(cf.format(s.amount), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
                        ]))),
                  ])));
        }).toList());
  }

  IconData _icon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.bkash: return Icons.phone_android;
      case PaymentMethod.nagad: return Icons.smartphone;
      case PaymentMethod.bankCard: return Icons.credit_card;
      case PaymentMethod.cash: return Icons.money;
      default: return Icons.payment;
    }
  }

  Color _color(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.bkash: return const Color(0xFFE2136E);
      case PaymentMethod.nagad: return const Color(0xFFED1C24);
      case PaymentMethod.bankCard: return const Color(0xFF1565C0);
      case PaymentMethod.cash: return Colors.green;
      default: return Colors.blue;
    }
  }
}

extension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}