import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'state/transaction_store.dart';
import 'state/subscription_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseEnabled = true;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) {
      // Android: Firebase is configured via google-services.json (Gradle plugin).
      // Web: firebase_options.dart provides the config.
      if (!kIsWeb) {
        await Firebase.initializeApp();
      } else {
        // Web with no explicit config - run in local-only mode
        firebaseEnabled = false;
      }
    } else {
      await Firebase.initializeApp(options: options);
    }
  } catch (error) {
    // Firebase initialization failed (e.g. google-services.json not found,
    // no internet, etc.) — fall back to local-only storage
    debugPrint('Firebase initialization failed: $error');
    firebaseEnabled = false;
  }
  runApp(MyApp(firebaseEnabled: firebaseEnabled));
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    this.firebaseEnabled = true,
  }) : super(key: key);

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionStore(firebaseEnabled: firebaseEnabled),
        ),
        ChangeNotifierProvider(
          create: (_) => SubscriptionStore(firebaseEnabled: firebaseEnabled),
        ),
      ],
      child: MaterialApp(
        title: 'Finance Predictor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: firebaseEnabled ? const _AuthGate() : const _AppEntry(),
      ),
    );
  }
}

/// Entry point that binds to local-demo-user and enables Firebase if available.
/// This avoids requiring Firebase Auth setup — the user can use the app
/// immediately and transactions sync to Firestore automatically.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    // Always bind to local-demo-user for immediate app usage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionStore>().bindToUser('local-demo-user');
      context.read<SubscriptionStore>().bindToUser('local-demo-user');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

class _FirebaseStartupErrorScreen extends StatelessWidget {
  const _FirebaseStartupErrorScreen({required this.error});

  final FirebaseException error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Firebase not initialized',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Fix: create Firebase web config with FlutterFire and add the generated firebase_options.dart file, then relaunch the web app.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<TransactionStore>().unbindUser();
            context.read<SubscriptionStore>().unbindUser();
          });
          return const AuthScreen();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<TransactionStore>().bindToUser(user.uid);
          context.read<SubscriptionStore>().bindToUser(user.uid);
        });
        return const HomeScreen();
      },
    );
  }
}
