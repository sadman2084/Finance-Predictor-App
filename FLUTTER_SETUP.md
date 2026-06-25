# Flutter Setup & Firebase Integration Guide

## 📋 Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode
- Firebase account (free tier)
- Git

## 🔧 Initial Setup

### 1. Create Flutter Project (if starting fresh)
```bash
cd mobile/
flutter pub get
```

### 2. Firebase Configuration

#### For Android:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create project: "finance-predictor"
3. Register Android app
4. Download `google-services.json`
5. Place at: `android/app/google-services.json`

#### For iOS:
1. Register iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Place in Xcode: Targets → Build Phases → Copy Bundle Resources

### 3. Firestore Database Schema

```
users/
├── {userId}
│   ├── full_name: string
│   ├── monthly_income: number
│   ├── persona: string (student | freelancer | family | salaried)
│   └── created_at: timestamp

transactions/
├── {transactionId}
│   ├── user_id: string
│   ├── txn_date: date
│   ├── amount: number
│   ├── category: string
│   ├── channel: string (cash | bkash | nagad | rocket | bank)
│   ├── description: string
│   └── created_at: timestamp

monthly_summary/
├── {userId}_2026_03
│   ├── user_id: string
│   ├── month: number
│   ├── year: number
│   ├── total_income: number
│   ├── total_expense: number
│   ├── savings: number
│   └── updated_at: timestamp
```

### 4. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - readable by owner only
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }

    // Transactions - readable/writable by owner
    match /transactions/{transactionId} {
      allow read: if request.auth.uid == resource.data.user_id;
      allow create: if request.auth.uid == request.resource.data.user_id;
      allow update, delete: if request.auth.uid == resource.data.user_id;
    }

    // Monthly summaries
    match /monthly_summary/{docId} {
      allow read: if request.auth != null;
      allow write: if false; // Write only via Cloud Function
    }
  }
}
```

## 📱 Environment Configuration

### Create `.env` file (optional):
```
FIREBASE_API_KEY=your_key
FIREBASE_PROJECT_ID=finance-predictor
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
PYTHON_API_URL=https://your-backend.run.app/api/v1
```

## 🔗 Backend Integration

### Add to your service layer:

```dart
// lib/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addTransaction(Transaction txn) async {
    await _db.collection('transactions').add(txn.toMap());
  }

  Stream<List<Transaction>> getUserTransactions(String userId) {
    return _db
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('txn_date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList());
  }
}
```

## 🚀 Running the App

```bash
# Run on Android emulator
flutter run

# Run on iOS simulator
flutter run -d macos

# Run on specific device
flutter run -d <device-id>

# Build APK for release
flutter build apk --split-per-abi --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## 📊 Next: Connect Python Backend

Update `add_tab.dart` to call your Python FastAPI:

```dart
import 'package:http/http.dart' as http;

Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    final response = await http.post(
      Uri.parse('https://your-api.run.app/api/v1/transactions/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'txn_date': _selectedDate.toIso8601String(),
        'amount': double.parse(_amountController.text),
        'category': _selectedCategory,
        'channel': _selectedChannel.name,
        'description': _descriptionController.text,
      }),
    );
    
    if (response.statusCode == 200) {
      // Success
    }
  }
}
```

## 🧪 Testing

```bash
flutter test
```

## 📚 Useful Links

- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [fl_chart Documentation](https://pub.dev/packages/fl_chart)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
