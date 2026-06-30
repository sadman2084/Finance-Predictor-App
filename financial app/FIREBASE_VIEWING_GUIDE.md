# 🔥 Firebase Console: Step-by-Step Data Viewing Guide

## 🚀 Quick Start: Open Firebase Console

1. **Go to Firebase:** https://console.firebase.google.com
2. **Select Your Project:** "Finance Predictor" 
3. **Navigate to Firestore Database**

---

## 📍 Navigate to Your Collections

Once in Firestore Database:

```
Left Sidebar → Firestore Database
  └── View Collections button (if needed)
      └── users (collection)
          └── {Your User ID} (document)
              ├── transactions (subcollection)
              ├── debts (subcollection)
              ├── emergency_fund (subcollection)
              ├── chat_history (subcollection) ← NEW!
              ├── monthly_plans (subcollection)
              └── health_snapshots (subcollection)
```

---

## 🔍 View SMS/Receipt Data (Transactions)

**Step 1:** Click on `users`
**Step 2:** Click on your User ID
**Step 3:** Click on `transactions` (subcollection)

You'll see all SMS and receipt imports:
- Timestamp ID
- Amount
- Category (food, shopping, salary, etc.)
- Channel (cash, bKash, Nagad, etc.)
- Description
- Transaction type (expense/income)

**Example View:**
```
Document ID: 1718899234567890
Fields:
├─ amount: 500
├─ category: "food"
├─ channel: "cash"
├─ created_at: June 20, 2026 at 2:30:45 PM
├─ date: June 20, 2026 at 12:00:00 AM
├─ description: "bKash Payment"
├─ id: "1718899234567890"
├─ type: "expense"
└─ user_id: "{your-user-id}"
```

---

## 💳 View Debt Tracker Data

**Step 1:** Click on `users`
**Step 2:** Click on your User ID
**Step 3:** Click on `debts` (subcollection)

You'll see all loans and debts:
- Debt name
- Principal amount
- Amount paid so far
- Monthly payment
- Interest rate
- Due date
- Whether you lent or borrowed

**Example View:**
```
Document ID: 1718899234567891
Fields:
├─ name: "Car Loan"
├─ principal: 500000
├─ paid: 50000
├─ monthly_payment: 10000
├─ interest_rate: 5.5
├─ due_date: June 2029
├─ is_lent: false
├─ note: "From Bank XYZ"
└─ created_at: June 20, 2026
```

---

## 🏦 View Emergency Fund Plan

**Step 1:** Click on `users`
**Step 2:** Click on your User ID
**Step 3:** Click on `emergency_fund` (subcollection)
**Step 4:** Click on `active` (document)

You'll see your emergency fund strategy:
- Current savings
- Target months of expenses
- Target fund amount
- Monthly contribution
- Last update time

**Example View:**
```
Document ID: active
Fields:
├─ monthly_expense: 15000
├─ current_savings: 50000
├─ target_months: 6
├─ target_amount: 90000
├─ monthly_contribution: 5000
└─ updated_at: June 20, 2026 at 3:45:20 PM
```

---

## 💬 View Chat History (NEW!)

**Step 1:** Click on `users`
**Step 2:** Click on your User ID
**Step 3:** Click on `chat_history` (subcollection)

You'll see all assistant conversations:
- Your message
- AI response
- Which panel it was from
- Timestamp

**Example View:**
```
Document ID: auto-generated
Fields:
├─ message: "How much should I save monthly?"
├─ response: "Based on your expenses, you should save..."
├─ panel: "Assistant"
└─ created_at: June 20, 2026 at 4:15:30 PM
```

---

## 📊 Search & Filter Your Data

### Filter by Date Range:
1. Open any collection
2. Click the filter icon (⊕)
3. Select field (e.g., `created_at`)
4. Choose ">" or "<" 
5. Set your date range

### Search/Query:
1. Open a collection
2. Click the first document to see the ID
3. Documents are sorted by creation (newest last)
4. Click any document to expand its fields

---

## 📈 Export Your Data

1. **Select multiple documents:** Click checkboxes
2. **Right-click** → "Export to CSV" (or JSON)
3. Choose your format and save

---

## 🔐 Monitor Data Growth

To see collection statistics:
1. Go to Firestore Database
2. Collection stats shown at bottom:
   - Number of documents
   - Storage size
   - Last updated

---

## ✨ What's Being Saved Now

| Panel | Collection | Auto-Save |
|-------|-----------|-----------|
| SMS Import | `transactions` | ✅ Yes |
| Receipt Scanner | `transactions` | ✅ Yes |
| Emergency Fund | `emergency_fund` | ✅ Yes (via "Save Plan" button) |
| Debt Tracker | `debts` | ✅ Yes (via "Add Debt" button) |
| Assistant Chat | `chat_history` | ✅ Yes (NEW - automatically after response) |
| Cashflow Calendar | None | — (read-only) |

---

## 🐛 Troubleshooting

### Data not showing up?
1. ✓ Are you logged in? (Check top-right)
2. ✓ Is it the correct user ID?
3. ✓ Did you click "Save Plan" or "Add Debt"?
4. ✓ Check app console for errors (Firebase section)

### Can't find Chat History?
- Make sure you've sent at least one message in the Assistant chat
- Refresh the Firebase console (F5)
- The collection might appear only after first save

### Timestamps look weird?
- Firebase shows times in UTC
- They're Firestore `Timestamp` type
- They'll display correctly in your app

---

## 🔗 Useful Links

- [Firebase Console](https://console.firebase.google.com)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Data Structure Overview](./FIREBASE_DATA_GUIDE.md)

---

## 💡 Pro Tips

1. **Real-time Updates:** Firestore shows live updates as you use the app
2. **Document IDs:** Most use microsecond timestamp (1718899234567890)
3. **Backup:** Export important collections periodically
4. **Security:** User data is isolated by `user_id` - no cross-user access
5. **Query:** In Python backend, use `db.collection('users').document(uid).collection('transactions')`
