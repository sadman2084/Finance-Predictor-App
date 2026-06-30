# Finance Predictor - Flutter Frontend

## 📱 Project Structure

```
lib/
├── main.dart                 # App entry point with Material theme
├── models/
│   ├── transaction_model.dart    # Transaction data class
│   └── user_model.dart           # User profile data class
├── screens/
│   ├── home_screen.dart          # Main screen with bottom navigation
│   ├── records_tab.dart          # Transaction history list
│   ├── charts_tab.dart           # Charts & visualization
│   ├── add_tab.dart              # Add new transaction form
│   └── reports_tab.dart          # Monthly reports & insights
└── widgets/
    └── (reusable components)
```

## 🎯 Screen Overview

### 1. **Records Tab** (Transaction Ledger)
- List all past transactions
- Display: Date, Category, Amount, Channel, Description
- Color-coded by category (Food=Orange, Groceries=Green, Transport=Blue, etc.)
- Sortable by date / category

### 2. **Charts Tab** (Visual Analytics)
- **Line Chart**: Monthly spending trend (Jan-Jun)
- **Pie Chart**: Category breakdown for current month
- Interactive tooltips showing exact amounts

### 3. **Add Tab** (Entry Form)
- Amount input (required)
- Category dropdown (food, groceries, transport, utilities, rent, mobile_recharge)
- Payment channel (cash, bKash, Nagad, Rocket, Bank)
- Date picker (max: today)
- Description (optional)
- Save button with validation

### 4. **Reports Tab** (Insights Dashboard)
- Monthly summary: Total Income / Total Spent / Savings
- Risk indicator (Low/Medium/High risk alert)
- Next month forecast with seasonal adjustment
- Personalized recommendations (Eid budgeting, wallet fee reduction, etc.)

## 🚀 Next Steps

1. **Firebase Setup**
   ```
   - Enable Firebase Authentication (Phone + Email + Google)
   - Create Firestore collections: users, transactions, monthly_summary
   - Set security rules for user-owned data
   - Enable Cloud Messaging for push notifications
   ```

2. **Connect to Backend**
   - Add HTTP/Dio service to call FastAPI endpoints
   - `/api/v1/transactions/` → POST/GET transactions
   - `/api/v1/insights/forecast` → Get predictions
   - `/api/v1/insights/risk` → Get risk status

3. **Ghana-local Features**
   - Add salary cycle dates (1-3, 25-27)
   - Add festive season flags (Eid, Puja months)
   - Mobile financial service logos (bKash, Nagad, etc.)

4. **State Management**
   - Integrate `provider` for transaction state
   - Sync Firestore with local cache

5. **Testing**
   ```bash
   flutter test
   ```

## 🛠️ Run Instructions

```bash
# Get dependencies
flutter pub get

# Run on emulator/device
flutter run

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## 📊 Widget Dependencies

- **fl_chart**: Line, Pie, Bar charts
- **Firebase**: Auth, Firestore, Cloud Messaging
- **Provider**: State management (optional, can use Riverpod)
- **Dio/Http**: API calls

## 🎨 UI Theme

- **Primary Color**: Blue
- **Cards**: Material elevation 2
- **Spacing**: Material Design guidelines
- **Currency**: Bengali Taka (৳)
- **Language**: English (ready for Bangla i18n)
