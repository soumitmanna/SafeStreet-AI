# 🛡️ SafeStreet

<div align="center">

### AI-Powered Emergency Response & Personal Safety Mobile Application

Built with **Flutter**, **Firebase**, and **Google Maps**

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Cloud-orange?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Under%20Development-success)

</div>

---

# 📖 Overview

SafeStreet is a smart emergency response mobile application developed using Flutter and Firebase to enhance personal safety through real-time SOS alerts, trusted contacts, live location sharing, evidence capture, and volunteer assistance.

The application enables users to instantly notify trusted contacts, create emergency alerts with GPS coordinates, attach photo/video evidence, and receive assistance from nearby volunteers.

---

# ✨ Features

## 🔐 Authentication

- Firebase Authentication
- Secure Login
- User Registration
- Session Management

---

## 🏠 Home Dashboard

- Clean Material 3 UI
- Quick access to all safety features
- Responsive layout

---

## 👥 Trusted Contacts

- Add trusted contacts
- Edit contacts
- Delete contacts
- Duplicate prevention
- Phone number validation

---

## 🚨 SOS Emergency System

- One-tap SOS activation
- Live GPS location
- Firestore alert creation
- SMS notifications to trusted contacts
- Google Maps location link
- Error handling & permission management

---

## 📸 Evidence Capture

- Capture photos
- Select from gallery
- Preview evidence
- Local storage
- Attach evidence before SOS
- Delete evidence

---

## ⏱ Journey Timer

- Safe travel timer
- Countdown
- Automatic SOS trigger
- Manual cancellation

---

## 📍 Live Alerts

- Real-time Firestore updates
- Active alert feed
- Status badges
- Relative timestamps
- Responsive cards

---

## 📄 Alert Details

- Live alert information
- Victim details
- GPS coordinates
- Timestamp
- Google Maps integration
- Accept alert

---

## 🤝 Volunteer Assistance

- Accept emergency
- Live status updates
- Distance calculation
- Open navigation
- Mark arrival
- Resolve incident

---

# 🏗 Architecture

```
                 Flutter UI
                      │
      ┌───────────────┼───────────────┐
      │               │               │
      ▼               ▼               ▼
 Authentication    Services       Utilities
      │               │               │
      └───────────────┼───────────────┘
                      │
                Cloud Firestore
                      │
                 Firebase Auth
```

The application follows a modular architecture with:

- Presentation Layer
- Service Layer
- Data Models
- Utility Helpers
- Firebase Backend

---

# 📂 Project Structure

```
lib/
│
├── models/
│   ├── alert_model.dart
│   ├── contact_model.dart
│   └── evidence_model.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── sos_screen.dart
│   ├── contacts_screen.dart
│   ├── alerts_screen.dart
│   ├── alert_details_screen.dart
│   ├── volunteer_assistance_screen.dart
│   ├── evidence_screen.dart
│   ├── journey_timer_screen.dart
│   └── ...
│
├── services/
│   ├── alert_service.dart
│   ├── sos_service.dart
│   ├── contact_service.dart
│   ├── evidence_service.dart
│   ├── communication_service.dart
│   └── location_service.dart
│
├── utils/
│   ├── alert_ui_helper.dart
│   └── ...
│
└── main.dart
```

---

# 🛠 Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | Mobile Development |
| Dart | Programming Language |
| Firebase Authentication | User Authentication |
| Cloud Firestore | Real-time Database |
| Google Maps | Navigation |
| Geolocator | GPS Services |
| URL Launcher | External Maps |
| Material 3 | UI Design |
| Git & GitHub | Version Control |

---

# 🔄 Application Workflow

```
User Login
      │
      ▼
Home Screen
      │
      ▼
SOS Activated
      │
      ▼
GPS Location
      │
      ▼
Evidence (Optional)
      │
      ▼
Firestore Alert
      │
      ▼
Trusted Contacts Notified
      │
      ▼
Live Alerts Feed
      │
      ▼
Volunteer Accepts
      │
      ▼
Navigation
      │
      ▼
Arrived
      │
      ▼
Resolved
```

---

# 🚀 Installation

## Clone Repository

```bash
git clone https://github.com/soumitmanna/SafeStreet.git
```

---

## Open Project

```bash
cd SafeStreet/mobile_app
```

---

## Install Packages

```bash
flutter pub get
```

---

## Configure Firebase

Add:

- google-services.json (Android)
- Google Maps API Key
- Firebase Project Configuration

---

## Run

```bash
flutter run
```

---

# 📱 Screens

- Login
- Register
- Home
- Contacts
- SOS
- Evidence
- Journey Timer
- Alerts
- Alert Details
- Volunteer Assistance

---

# 🔥 Firebase Collections

## alerts

```
alertId
userId
userEmail
status
createdAt
resolved
location
latitude
longitude
acceptedBy
acceptedEmail
acceptedAt
arrived
arrivedAt
```

---

# 📊 Current Progress

| Module | Status |
|---------|---------|
| Authentication | ✅ |
| Home | ✅ |
| Contacts | ✅ |
| SOS | ✅ |
| Evidence | ✅ |
| Journey Timer | ✅ |
| Live Alerts | ✅ |
| Alert Details | ✅ |
| Volunteer Assistance | ✅ |

Overall Completion:

**~90%**

---

# 🔒 Future Improvements

- Push Notifications
- Offline Support
- Cloud Storage for Evidence
- AI Risk Detection
- Nearby Volunteer Matching
- Live Volunteer Tracking
- Emergency Analytics Dashboard

---

# 🤝 Contributors

**Soumit Manna**

B.Tech CSE (AI)

3rd Year
Institute of Engineering & Management (IEM)


---

# 📄 License

This project is developed for academic and educational purposes.

---

# ⭐ Acknowledgements

- Flutter Team
- Firebase
- Google Maps Platform
- Material Design
- Open Source Community

---

<div align="center">

### 🛡️ SafeStreet

### Building Safer Communities Through Technology

⭐ If you like this project, consider giving it a star!

</div>