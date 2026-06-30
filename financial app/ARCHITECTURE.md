# Architecture & Data Flow

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP (iOS/Android)             │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   Records    │  │   Charts     │  │     Add      │            │
│  │   (Ledger)   │  │ (Analytics)  │  │ (Transaction)│            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐                              │
│  │   Reports    │  │  Auth/Sync   │                              │
│  │ (Dashboard)  │  │ (Firebase)   │                              │
│  └──────────────┘  └──────────────┘                              │
│                                                                   │
└───────────────────┬────────────────────┬────────────────────────┘
                    │                    │
                 Firebase            HTTP/REST
                 Auth/Firestore       API Calls
                    │                    │
        ┌───────────┘                    └─────────────┐
        │                                              │
        ▼                                              ▼
┌──────────────────────────────┐       ┌──────────────────────────┐
│  FIREBASE (Cloud Backend)    │       │  PYTHON FastAPI Server   │
├──────────────────────────────┤       ├──────────────────────────┤
│ • Authentication             │       │ • Transaction CRUD       │
│ • Firestore (Realtime DB)    │       │ • Insights Endpoints     │
│ • Cloud Messaging (Push)     │       │ • Data Validation        │
│ • Cloud Storage              │       │ • Authentication Proxy   │
│                              │       │                          │
│ Collections:                 │       │ API Routes:              │
│ ├─ users                     │       │ ├─ /api/v1/health/       │
│ ├─ transactions              │       │ ├─ /api/v1/transactions  │
│ └─ monthly_summary           │       │ ├─ /api/v1/insights/     │
│                              │       │ │  ├─ /forecast          │
└──────────────────────────────┘       │ │  ├─ /risk              │
         ▲                              │ │  └─ /recommendations   │
         │                              │ └─ /api/v1/ml/train     │
         └──────────────────────        └──────────────┬──────────┘
                      │                               │
            Schedule Job Trigger            ┌────────┴──────────┐
            (Cloud Function)                │                   │
                                            ▼                   ▼
                                    ┌────────────────┐  ┌──────────────┐
                                    │  PostgreSQL    │  │  ML Pipeline │
                                    │   Database     │  ├──────────────┤
                                    ├────────────────┤  │ • Forecast   │
                                    │ • users        │  │ • Risk Class │
                                    │ • transactions │  │ • Clustering │
                                    │ • predictions  │  │              │
                                    │ • summaries    │  │ Models:      │
                                    └────────────────┘  │ ├─ Prophet   │
                                                        │ ├─ LSTM      │
                                                        │ ├─ XGBoost   │
                                                        │ └─ KMeans    │
                                                        └──────────────┘
                                                             │
                                                        ┌────┴────┐
                                                        │          │
                                                    Training   Prediction
                                                    (Offline)  (API Call)
```

---

## 🔄 Data Flow Diagram

### **1. User Adds Transaction**
```
User Input (Add Tab)
    ↓
Form Validation (Flutter)
    ↓
HTTP POST → /api/v1/transactions/
    ↓
FastAPI receives request
    ↓
Category Normalization (categorizer.py)
    ↓
Store in PostgreSQL
    ↓
Response: {id, created_at, ...}
    ↓
Save to Firestore (sync)
    ↓
App shows success message
```

### **2. Generate Monthly Forecast**
```
User opens Reports Tab
    ↓
Trigger: GET /api/v1/insights/forecast?user_id=123
    ↓
FastAPI fetches user transactions (last 6 months)
    ↓
Feature Engineering:
    - Add Bangladesh context (salary cycle, festive date)
    - Normalize amounts
    - Calculate rolling averages
    ↓
ML Pipeline runs:
    1. Prophet or LSTM model
    2. Next 3 months prediction
    3. Apply seasonal multiplier (12% for Eid season)
    ↓
Return: [{period, predicted_expense}, ...]
    ↓
Display on Charts Tab (line chart)
```

### **3. Risk Detection**
```
Background Job (Cloud Function or scheduled)
    ↓
Get all user transactions (current month)
    ↓
Calculate spending ratio: total_spent / monthly_income
    ↓
ML Classification: status = classify_overspending_risk()
    ↓
Output: risk_score ∈ [0, 1]
    - score >= 0.75 → HIGH RISK
    - score >= 0.45 → MEDIUM RISK
    - score < 0.45 → LOW RISK
    ↓
If risk >= threshold:
    - Send Push Notification (FCM)
    - Update Firestore risk_alert collection
    ↓
App fetches: GET /api/v1/insights/risk?user_id=123
    ↓
Display alert on Reports Tab
```

### **4. Training New Model (Monthly)**
```
Monthly Scheduler Trigger
    ↓
Collect training data:
    - All transactions (6+ months)
    - User profiles (income, persona)
    ↓
Run: train_pipeline(dataset_path) 
    ↓
Feature Engineering:
    - Bangladesh salary cycle flags
    - Festive season encodings
    - Channel-based patterns
    ↓
Train 3 models:
    1. Prophet (time-series) → forecast.pkl
    2. XGBoost (classifier) → risk.pkl
    3. KMeans (clustering) → personas.pkl
    ↓
Save artifacts to Cloud Storage
    ↓
Load models into API server
    ↓
Next prediction uses updated model
```

---

## 💾 Database Schema (PostgreSQL)

### **users table**
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    monthly_income DECIMAL(12, 2) DEFAULT 0,
    persona VARCHAR(50),  -- 'student', 'family', 'salaried', 'freelancer'
    created_at TIMESTAMP DEFAULT NOW()
);
```

### **transactions table**
```sql
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    txn_date DATE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    category VARCHAR(60) NOT NULL,
    channel VARCHAR(50) DEFAULT 'cash',  -- bkash, nagad, cash, bank
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_user_date (user_id, txn_date)
);
```

### **Firestore Collections** (Sync from PostgreSQL)
```
users/{userId}
├─ full_name: string
├─ monthly_income: number
├─ persona: string
└─ synced_at: timestamp

transactions/{transactionId}
├─ user_id: string
├─ txn_date: date
├─ amount: number
├─ category: string
├─ channel: string
└─ created_at: timestamp
```

---

## 🔗 API Contract Examples

### **Add Transaction**
```
POST /api/v1/transactions/
Content-Type: application/json

{
  "user_id": 1,
  "txn_date": "2026-03-30",
  "amount": 500.50,
  "category": "food",
  "channel": "cash",
  "description": "Lunch at restaurant"
}

Response 200:
{
  "id": 42,
  "user_id": 1,
  "txn_date": "2026-03-30",
  "amount": 500.50,
  "category": "food",
  "channel": "cash",
  "description": "Lunch at restaurant",
  "created_at": "2026-03-30T14:22:15"
}
```

### **Get Forecast**
```
GET /api/v1/insights/forecast?user_id=1

Response 200:
[
  {
    "period": "2026-04",
    "predicted_expense": 25800.00
  },
  {
    "period": "2026-05",
    "predicted_expense": 28900.00  // Seasonal boost (Eid)
  },
  {
    "period": "2026-06",
    "predicted_expense": 24500.00
  }
]
```

### **Get Risk Status**
```
GET /api/v1/insights/risk?user_id=1

Response 200:
{
  "risk_level": "low",
  "risk_score": 0.32,
  "reason": "Projected spending appears manageable based on recent behavior."
}
```

---

## 🌍 Bangladesh Contextual Features

### **Salary Cycle**
Days 1-3 and 25-27 are most common in Bangladesh:
```python
is_salary_cycle_day = day in [1, 2, 3, 25, 26, 27]
```

### **Festive Season Spending**
Higher spending during Eid and Durga Puja:
```python
FESTIVE_MONTHS = {3, 4, 5, 9, 10}  # Approximate (vary by lunar calendar)
seasonal_multiplier = 1.12 if is_festive else 1.0
```

### **Mobile Financial Services**
Popular payment channels in Bangladesh:
- **bKash** - Largest mobile wallet
- **Nagad** - Government-backed
- **Rocket** - Bank-operated
- **Upay** - Less common
- **Bank Transfer** - Traditional

### **Spending Patterns by PersonA**
```
Student:
- High food/transport spending
- Low utilities/rent (shared)
- Seasonal (tuition, exam periods)

Salaried:
- Regular income (salary cycle)
- Fixed utilities (rent, insurance)
- Variable discretionary

Freelancer:
- Irregular income
- Higher transport (client meetings)
- Business expenses

Family:
- High groceries/utilities
- Child-related (education, health)
- Seasonal (Eid gifts, celebrations)
```

---

**Diagram Version:** 1.0  
**Last Updated:** March 30, 2026
