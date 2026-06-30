import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'records_tab.dart';
import 'charts_tab.dart';
import 'add_tab.dart';
import 'reports_tab.dart';
import 'more_tab.dart';
import 'subscriptions_tab.dart'; // Import the new subscriptions tab

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
        const RecordsTab(),
        const ChartsTab(),
        const AddTab(),
        const ReportsTab(),
        const SubscriptionsTab(), // Add SubscriptionsTab here
        const MoreTab(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finance Predictor"),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.3),
        actions: [
          IconButton(
            tooltip: "More tools",
            onPressed: () {
              setState(() {
                _selectedIndex = 5; // Update index for More tab
              });
            },
            icon: const Icon(Icons.dashboard_customize),
          ),
          IconButton(
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return NavigationBar(
            selectedIndex: _selectedIndex,
            labelBehavior: isWide
                ? NavigationDestinationLabelBehavior.alwaysShow
                : NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: "Records",
              ),
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: "Charts",
              ),
              const NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: "Add",
              ),
              const NavigationDestination(
                icon: Icon(Icons.assessment_outlined),
                selectedIcon: Icon(Icons.assessment),
                label: "Reports",
              ),
              const NavigationDestination(
                icon: Icon(Icons.subscriptions_outlined), // Icon for subscriptions
                selectedIcon: Icon(Icons.subscriptions), // Selected icon
                label: "Subscriptions",
              ),
              const NavigationDestination(
                icon: Icon(Icons.dashboard_customize_outlined),
                selectedIcon: Icon(Icons.dashboard_customize),
                label: "More",
              ),
            ],
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          );
        },
      ),
    );
  }
}
