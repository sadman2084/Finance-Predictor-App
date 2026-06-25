# Firebase Setup Checklist

## 🎯 Complete this before running the app

### 1. Firebase Project Creation
- [ ] Go to https://console.firebase.google.com/
- [ ] Click "Create Project"
- [ ] Project name: `finance-predictor`
- [ ] Enable Google Analytics (optional)
- [ ] Create project

### 2. Android Setup
- [ ] In Firebase Console → Project Settings → Your apps
- [ ] Register new Android app
- [ ] Package name: `com.finance.predictor`
- [ ] Download `google-services.json`
- [ ] Move to: `mobile/android/app/google-services.json`
- [ ] In `android/app/build.gradle`, ensure:
  ```gradle
  apply plugin: 'com.google.gms.google-services'
  ```
- [ ] In `android/build.gradle`, add:
  ```gradle
  classpath 'com.google.gms:google-services:4.3.15'
  ```

### 3. iOS Setup (Optional)
- [ ] Register iOS app in Firebase Console
- [ ] Bundle ID: `com.finance.predictor`
- [ ] Download `GoogleService-Info.plist`
- [ ] Open `mobile/ios/Runner.xcworkspace` in Xcode
- [ ] Add `GoogleService-Info.plist` via Xcode UI
- [ ] Ensure it's in "Copy Bundle Resources" build phase

### 4. Enable Authentication
- [ ] In Firebase Console → Authentication → Sign-in methods
- [ ] Enable: Email/Password
- [ ] Enable: Google
- [ ] Enable: Phone (optional)

### 5. Firestore Database
- [ ] In Firebase Console → Firestore Database → Create database
- [ ] Start in **Test mode** (or follow production rules below)
- [ ] Select region: `asia-southeast1` (Singapore, closest to BD)

### 6. Set Security Rules
Copy this into Firestore Rules editor:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /transactions/{transactionId} {
      allow read: if request.auth.uid == resource.data.user_id;
      allow create: if request.auth.uid == request.resource.data.user_id;
      allow update, delete: if request.auth.uid == resource.data.user_id;
    }
    match /monthly_summary/{docId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

### 7. Cloud Messaging (Push Notifications)
- [ ] In Firebase Console → Cloud Messaging
- [ ] Generate Server API key
- [ ] Note: Flutter will auto-handle FCM tokens

### 8. Create Collections (Optional - can be auto-created)
- [ ] `users` - User profiles
- [ ] `transactions` - All transactions
- [ ] `monthly_summary` - Aggregated monthly data

### 9. Test Connection
- [ ] Run `flutter run`
- [ ] App should launch without Firebase errors
- [ ] Check Firebase Console for app event data

---

## 🔧 Environment Variables (Backend)

Create `backend/.env`:
```
POSTGRES_SERVER=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secure_password_here
POSTGRES_DB=finance_db

FIREBASE_CREDENTIALS_PATH=/path/to/serviceAccountKey.json
CORS_ORIGINS=["http://localhost:3000", "https://yourdomain.com"]
```

---

## ✅ Quick Verification

After setup, check:
1. `mobile/android/app/google-services.json` exists
2. `mobile/ios/GoogleService-Info.plist` exists (if iOS)
3. Firebase Console shows events when app runs
4. Firestore Collections visible in Console

---

**Time to complete:** ~15 minutes  
**Support:** Check FLUTTER_SETUP.md for detailed steps
