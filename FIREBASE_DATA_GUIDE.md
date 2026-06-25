# Firebase Data Structure & Viewing Guide for More Tab

## 📊 Where Your Data is Stored

All data from the **More Tab** is being saved to **Cloud Firestore** under this structure:

```
Cloud Firestore
└── users/{userId}/
    ├── transactions/          (SMS & Receipt imports)
    ├── debts/                 (Debt Tracker entries)
    ├── emergency_fund/        (Emergency Fund Plan)
    ├── monthly_plans/         (Budget plans)
    ├── what_if_history/       (Scenario analysis)
    └── health_snapshots/      (Financial health scores)
```

---

## 📱 More Tab Data Breakdown

### 1. **SMS/Bank Message Import**
**Panel:** SMS tab  
**Firebase Path:** `users/{userId}/transactions/`  
**What's Saved:**
- Amount, Date, Category (detected by AI)
- Channel (bKash, Nagad, Rocket, Bank)
- Description

**View in Firebase Console:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Firestore Database**
4. Navigate: `users` → `{Your User ID}` → `transactions`
5. You'll see all parsed transactions with ID as timestamp

**Example Document:**
```json
{
  "id": "1718899234567890",
  "amount": 500,
  "category": "food",
  "channel": "cash",
  "date": "Timestamp: June 20, 2026",
  "description": "bKash Payment",
  "type": "expense",
  "user_id": "{userId}",
  "created_at": "Timestamp"
}
```

---

### 2. **AI Receipt Scanner**
**Panel:** Receipt tab  
**Firebase Path:** `users/{userId}/transactions/`  
**What's Saved:**
- Same as SMS (stores as transaction)
- Scanned from image or manual text
- Automatically marked as "expense"

**View in Firebase Console:**
- Same path as SMS: `users/{userId}/transactions`
- Filter for documents created from receipt scan

---

### 3. **Emergency Fund Planner**
**Panel:** Emergency tab  
**Firebase Path:** `users/{userId}/emergency_fund/active`  
**What's Saved:**
- Current savings amount
- Target months of expenses
- Monthly contribution
- Target fund amount
- Last updated timestamp

**View in Firebase Console:**
1. Navigate: `users` → `{Your User ID}` → `emergency_fund`
2. Click on document `"active"`
3. You'll see:

```json
{
  "monthly_expense": 15000,
  "current_savings": 50000,
  "target_months": 6,
  "target_amount": 90000,
  "monthly_contribution": 5000,
  "updated_at": "Timestamp: June 20, 2026"
}
```

---

### 4. **Debt/Loan Tracker**
**Panel:** Debt tab  
**Firebase Path:** `users/{userId}/debts/{debtId}`  
**What's Saved:**
- Debt name
- Principal amount & paid amount
- Monthly payment
- Interest rate
- Due date
- Whether it's a loan you gave or received

**View in Firebase Console:**
1. Navigate: `users` → `{Your User ID}` → `debts`
2. Each debt is a separate document (ID = timestamp when created)
3. You'll see:

```json
{
  "id": "1718899234567891",
  "name": "Car Loan",
  "principal": 500000,
  "paid": 50000,
  "monthly_payment": 10000,
  "interest_rate": 5.5,
  "due_date": "Timestamp: June 2029",
  "is_lent": false,
  "note": "From Bank XYZ",
  "created_at": "Timestamp"
}
```

---

### 5. **Cashflow Calendar**
**Panel:** Calendar tab  
**Firebase Path:** `users/{userId}/transactions/` + `users/{userId}/debts/`  
**What's Happening:**
- This panel READS from transactions & debts (doesn't save separately)
- Shows 30-day projection based on existing data

**View in Firebase Console:**
- No separate collection needed
- Calculated from `transactions` and `debts` data

---

### 6. **Assistant Chat**
**Panel:** Assistant tab  
**Firebase Path:** Currently in-memory only  
**What's Happening:**
- Chats are NOT currently saved to Firebase
- Only sent to backend API for AI response

**To Add Chat History:** See "Modifications Needed" below

---

## 🔧 Modifications Needed

### ✅ Currently Working:
- ✓ SMS Import → Firestore `transactions`
- ✓ Receipt Scan → Firestore `transactions`
- ✓ Emergency Fund → Firestore `emergency_fund`
- ✓ Debt Tracker → Firestore `debts`

### ⚠️ Could Be Enhanced:
1. **Assistant Chat History** - Currently not saved
2. **Chat messages source** - Add a `chat_history` collection

### 🚀 To Save Chat History to Firebase

Add this method to `lib/state/transaction_store.dart`:

```dart
Future<void> saveChatMessage({
  required String message,
  required String response,
  required String panel, // 'SMS', 'Receipt', 'Emergency', 'Debt', etc.
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
```

Then modify `lib/screens/more_tab.dart` in the `_AssistantChatPanelState._send()` method to call this.

---

## 📈 Accessing Data Programmatically

To read data in your backend (Python):

```python
from firebase_admin import firestore

db = firestore.client()

# Get all transactions for a user
transactions = db.collection('users').document(user_id) \
    .collection('transactions').stream()

# Get emergency fund plan
emergency_fund = db.collection('users').document(user_id) \
    .collection('emergency_fund').document('active').get()

# Get all debts
debts = db.collection('users').document(user_id) \
    .collection('debts').stream()
```

---

## 🔐 Security Rules Recommendation

In Firebase Console → Firestore → Rules, ensure you have:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## 🎯 Next Steps

1. **View Your Data:** Open [Firebase Console](https://console.firebase.google.com)
2. **Navigate:** Firestore → Your Project → Collections
3. **See All Collections:**
   - `users` → select your user ID
   - Explore: `transactions`, `debts`, `emergency_fund`, etc.

4. **Optional:** Implement chat history saving using the code above

---

## 📝 Notes
- All timestamps are stored as Firestore `Timestamp` type
- Amounts are in BDT (Bengali Taka)
- Document IDs use microsecond timestamps for uniqueness
- All data is automatically synced in real-time via StreamSubscription in `TransactionStore`
