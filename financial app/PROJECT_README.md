# AI Personal Finance & Expense Predictor
## Bangladesh-Focused Smart Money Management

Complete project scaffold with Flutter frontend, FastAPI backend, and ML pipeline.

---

## 📦 Project Structure

```
financial app/
├── backend/                          # Python FastAPI backend
│   ├── app/
│   │   ├── api/v1/
│   │   │   ├── endpoints/
│   │   │   │   ├── health.py        # Health check
│   │   │   │   ├── transactions.py  # CRUD transactions
│   │   │   │   └── insights.py      # Forecast, risk, recommendations
│   │   │   └── router.py            # API routes
│   │   ├── core/
│   │   │   └── config.py            # Settings, PostgreSQL config
│   │   ├── db/
│   │   │   ├── base.py              # SQLAlchemy base
│   │   │   ├── models.py            # User, Transaction models
│   │   │   └── session.py           # Database session
│   │   ├── ml/
│   │   │   ├── data/
│   │   │   │   └── preprocess.py    # Bangladesh feature engineering
│   │   │   ├── models/
│   │   │   │   ├── forecast.py      # LSTM/Prophet placeholder
│   │   │   │   ├── classify_risk.py # Overspending classifier
│   │   │   │   └── cluster_profiles.py # User segmentation
│   │   │   └── pipelines/
│   │   │       ├── predict.py       # Prediction pipeline
│   │   │       └── train.py         # Training pipeline
│   │   ├── services/
│   │   │   ├── categorizer.py       # Category normalization
│   │   │   ├── risk.py              # Risk detection logic
│   │   │   └── recommendation.py    # Savings recommendations
│   │   └── main.py                  # FastAPI app entry
│   ├── tests/
│   │   └── test_health.py           # Sample test
│   ├── requirements.txt             # Python dependencies
│   ├── .env.example                 # Environment template
│   ├── Dockerfile                   # Container image
│   └── docker-compose.yml           # Local dev stack
│
├── mobile/                          # Flutter app (iOS/Android)
│   ├── lib/
│   │   ├── main.dart               # App entry, Material theme
│   │   ├── models/
│   │   │   ├── transaction_model.dart
│   │   │   └── user_model.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart    # Bottom nav (4 tabs)
│   │   │   ├── records_tab.dart    # Transaction ledger
│   │   │   ├── charts_tab.dart     # Line + Pie charts
│   │   │   ├── add_tab.dart        # Add transaction form
│   │   │   └── reports_tab.dart    # Insights dashboard
│   │   └── widgets/
│   │       ├── transaction_list_item.dart
│   │       └── statistic_card.dart
│   ├── pubspec.yaml                # Flutter dependencies
│   ├── README.md                   # Flutter-specific guide
│   └── .gitignore
│
├── FLUTTER_SETUP.md                # Firebase & setup guide
└── PROJECT_README.md               # This file
```

---

## 🎯 Key Features

### **Frontend (Flutter)**
- ✅ Bottom navigation with 4 main tabs
- ✅ Transaction recording (6 categories, 5 payment channels)
- ✅ Visual analytics (line & pie charts)
- ✅ Monthly expense forecasting
- ✅ Risk detection alerts
- ✅ Personalized recommendations
- ✅ Bangladesh currency & localization

### **Backend (Python FastAPI)**
- ✅ RESTful API (transactions CRUD, insights endpoints)
- ✅ PostgreSQL integration with SQLAlchemy ORM
- ✅ ML-ready model structure (forecast, classify, cluster)
- ✅ Bangladesh context features (salary cycles, festive dates, mobile wallets)
- ✅ Docker + docker-compose for easy local dev

### **ML Pipeline**
- ✅ Time-series forecasting (Prophet/LSTM stub)
- ✅ Binary/ordinal risk classification
- ✅ User behavior clustering (KMeans stub)
- ✅ Local feature engineering (festive season, salary cycle flags)

---

## 🚀 Quick Start

### **Backend**
```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Run locally (uvicorn)
uvicorn app.main:app --reload --port 8000

# Or with Docker
docker-compose up -d

# Visit http://localhost:8000/docs (Swagger)
```

### **Frontend**
```bash
cd mobile

# Get Flutter dependencies
flutter pub get

# Run on device/emulator
flutter run

# Or specify target
flutter run -d <device-id>
```

---

## 📐 API Endpoints

### Health
- `GET /api/v1/health/` → `{"status": "ok"}`

### Transactions
- `POST /api/v1/transactions/` → Create transaction
- `GET /api/v1/transactions/` → List all transactions

### Insights
- `GET /api/v1/insights/forecast?user_id=1` → Monthly forecast (3 months)
- `GET /api/v1/insights/risk?user_id=1` → Risk level + score
- `GET /api/v1/insights/recommendations?user_id=1` → Savings tips

---

## 🏗️ Bangladesh-Specific Features

1. **Salary Cycle Detection**
   - Days 1-3, 25-27 (common BD salary dates)
   - Flag applied in `preprocess.py`

2. **Festive Season Adjustment**
   - March-May (Eid), Sept-Oct (Durga Puja)
   - 12% spending multiplier in forecast

3. **Mobile Payment Support**
   - bKash, Nagad, Rocket (Bangladesh leaders)
   - Wallet cashout fees tracked separately

4. **Currency & Language**
   - Bengali Taka (৳) display
   - Ready for Bangla i18n

---

## ⚙️ Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Flutter 3.0+ |
| Backend | FastAPI |
| Database | PostgreSQL |
| ORM | SQLAlchemy |
| Auth | Firebase Auth (TODO) |
| Realtime DB | Firebase/Firestore (TODO) |
| Charts | fl_chart |
| ML | scikit-learn, TensorFlow, Prophet |

---

## 📋 Development Roadmap

### Phase 1 (Done)
- ✅ Project structure & scaffolding
- ✅ FastAPI core + routes
- ✅ Flutter UI (4-tab home)
- ✅ DB models & schemas

### Phase 2 (Next)
- [ ] Firebase Authentication
- [ ] Firestore integration
- [ ] Real transaction sync
- [ ] Actual ML model training
- [ ] Push notifications

### Phase 3 (Future)
- [ ] SMS/Bank statement parsing
- [ ] Admin dashboard
- [ ] User analytics & retention
- [ ] fintech partner integrations
- [ ] Web dashboard (Next.js/React)

---

## 🔐 Security Notes

1. Never commit `.env` files with secrets
2. Use environment variables for sensitive config
3. Enable Firestore security rules (see `FLUTTER_SETUP.md`)
4. Use HTTPS for all API calls in production
5. Store JWT tokens securely on mobile

---

## 🤝 Next Steps

1. **Set up Firebase** (auth, Firestore, Cloud Messaging)
2. **Connect Flutter to backend** (HTTP/Dio service layer)
3. **Train ML models** with sample expense data
4. **Deploy backend** to Cloud Run / AWS / Heroku
5. **Beta test** with real users in Bangladesh

---

## 📞 Support & Questions

- Flutter: See `mobile/README.md`
- Backend: See backend root for API docs
- Firebase: See `FLUTTER_SETUP.md`
- ML: See `backend/app/ml/` directory

---

**Created:** March 30, 2026  
**Project Status:** MVP Scaffold (Ready for Development)
