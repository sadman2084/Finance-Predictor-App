#  Finance Predictor

A full-stack AI-powered personal finance management application built with **Flutter**, **FastAPI**,**Firebase**, and **Machine Learning**. The application helps users track income and expenses, predict future financial trends, analyze spending behavior, and receive intelligent financial insights.

---

## Features

###  Mobile Application

* User Registration & Login
* Secure Authentication
* Dashboard with Financial Overview
* Income & Expense Tracking
* Budget Management
* Transaction History
* Financial Reports
* Real-time Data Synchronization
* Responsive Flutter UI

###  Backend API

* RESTful API using FastAPI
* JWT Authentication
* PostgreSQL Database
* Firebase Integration
* CRUD Operations
* Secure API Endpoints
* Docker Support
* Automatic API Documentation

###  Machine Learning

* Expense Forecasting
* Income Prediction
* Financial Risk Detection
* Spending Pattern Analysis
* User Segmentation (Clustering)
* Intelligent Financial Recommendations

---

#  System Architecture

```text
                    Flutter Mobile App
                            │
                            │ REST API
                            ▼
                     FastAPI Backend
                     ┌──────────────┐
                     │ Authentication│
                     │ Business Logic│
                     │ ML Services   │
                     └──────────────┘
                       │         │
          PostgreSQL   │         │ Firebase
                │      │         │
                ▼      ▼         ▼
         User Data   Transactions Notifications
```

---

# 📂 Project Structure

```text
finance-predictor/
│
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   ├── ml/
│   │   └── database/
│   │
│   ├── requirements.txt
│   ├── Dockerfile
│   └── main.py
│
├── mobile/
│   ├── lib/
│   ├── assets/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── docs/
│
├── docker-compose.yml
│
└── README.md
```

---

# ⚙️ Getting Started

## 1. Clone Repository

```bash
git clone https://github.com/your-username/finance-predictor.git

cd finance-predictor
```

---

## 2. Backend Setup

Create Virtual Environment

```bash
python -m venv venv
```

Activate Environment

Windows

```bash
venv\Scripts\activate
```


## 3. Mobile Setup

Navigate

```bash
cd mobile
```

Install Packages

```bash
flutter pub get
```

Run App

```bash
flutter run
```

---

# 🔥 Firebase Configuration

Configure Firebase for Android and iOS.

### Android

Place

```
google-services.json
```

inside

```
android/app/
```



# Docker

Build

```bash
docker-compose build
```

Run

```bash
docker-compose up
```

Stop

```bash
docker-compose down
```

---

# Testing

Backend

```bash
pytest
```

Flutter

```bash
flutter test
```

---

# Database Schema

Main Tables

* Users
* Transactions
* Categories
* Budgets
* Predictions
* Notifications

---

# Machine Learning Models

The project includes several AI models:

* Financial Forecasting
* Expense Prediction
* Income Prediction
* Risk Detection
* User Clustering
* Spending Pattern Analysis

---

# Security

* JWT Authentication
* Password Hashing
* Environment Variables
* Secure API Access
* Database Validation
* Firebase Authentication

---

# Deployment

Backend

* Docker
* Google Cloud Run
* Heroku
* Railway
* Render

Mobile

* Google Play Store
* Apple App Store

---

# Roadmap

* AI Financial Assistant
* Voice Commands
* Bill Reminder
* OCR Receipt Scanner
* Investment Suggestions
* Multi-language Support
* Dark Mode Improvements
* Analytics Dashboard

---

# 🤝 Contributing

1. Fork the repository.
2. Create a new feature branch.

```bash
git checkout -b feature/new-feature
```

3. Commit your changes.

```bash
git commit -m "Add new feature"
```

4. Push your branch.

```bash
git push origin feature/new-feature
```

5. Open a Pull Request.

---

# 📄 License

This project is licensed under the MIT License.

---

# 📞 Support

If you encounter any issues or have suggestions, please open an issue in this repository.

---

## If you find this project helpful, don't forget to give it a star on GitHub!
