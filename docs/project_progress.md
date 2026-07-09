# SafeStreet Project Progress

## Project Overview
SafeStreet is a Flutter + Firebase based personal safety application designed to provide emergency SOS, live location sharing, volunteer assistance, journey monitoring, and future AI-powered safety features.

---

# Current Architecture

## Frontend
- Flutter
- Material UI

## Backend
- Firebase Authentication
- Cloud Firestore

## Maps & Location
- Google Maps SDK
- Geolocator
- url_launcher

## Main Collections

### alerts
Stores active SOS alerts.

Fields:

- alertId
- userId
- userEmail
- latitude
- longitude
- location
- status
- resolved
- createdAt
- acceptedBy
- acceptedEmail
- acceptedAt

---

# File Structure

lib/

├── screens/

│ ├── home_screen.dart

│ ├── login_screen.dart

│ ├── signup_screen.dart

│ ├── sos_screen.dart

│ ├── assist_screen.dart

│ ├── assist_feed_screen.dart

│ ├── rescue_screen.dart

│ ├── journey_timer_screen.dart

│ ├── alerts_screen.dart

│ ├── contacts_screen.dart

│ ├── profile_screen.dart

│ ├── camera_screen.dart

│ └── location_screen.dart

│

├── services/

│ ├── sos_service.dart

│ ├── assist_service.dart

│ └── alert_service.dart

│

├── widgets/

├── theme/

└── main.dart

---

# Completed Phases

## Phase 1 — Authentication ✅

Implemented:

- Firebase Authentication
- Login
- Signup

Files:

- login_screen.dart
- signup_screen.dart

---

## Phase 2 — SOS System ✅

Implemented:

- SOS button
- Firestore alert creation
- Current location capture

Files:

- sos_screen.dart
- sos_service.dart

---

## Phase 3 — Victim Assist Screen ✅

Implemented:

- Active SOS screen
- End SOS
- Status updates
- Return to Home

Files:

- assist_screen.dart

---

## Phase 4 — Volunteer Feed ✅

Implemented:

- Active alerts list
- HELP NOW button
- Developer mode for one-device testing

Files:

- assist_feed_screen.dart
- assist_service.dart

---

## Phase 5 — Rescue Screen ✅

Implemented:

- Google Maps integration
- Victim marker
- Volunteer marker
- Live Firestore listener

Files:

- rescue_screen.dart

---

## Phase 6 — Distance & ETA ✅

Implemented:

- Distance calculation
- ETA estimation
- Volunteer location tracking

Files:

- rescue_screen.dart

---

## Phase 7 — External Navigation ✅

Implemented:

- Open Google Maps
- Navigate to victim location

Files:

- rescue_screen.dart

---

## Phase 8 — Journey Timer System ✅

Implemented:

- Custom hours input
- Custom minutes input
- Start Journey
- Stop Journey Safely
- Timer countdown
- Auto SOS trigger
- Auto AssistScreen opening
- Reuse SosService

Files:

- journey_timer_screen.dart

---

# Current Status

Core MVP completed.

Working modules:

✅ Authentication

✅ SOS Flow

✅ Live Location

✅ Volunteer System

✅ Rescue Screen

✅ Google Maps Navigation

✅ Journey Timer

---

# Pending Phases

## Phase 9 — Trusted Contacts

Goal:

Notify trusted contacts during SOS.

Features:

- Add contacts
- Edit contacts
- Delete contacts
- Auto call
- SMS alerts

Files:

- contacts_screen.dart

Status:

Not started

---

## Phase 10 — Camera Evidence Module

Goal:

Collect evidence during emergency.

Features:

- Capture image
- Record video
- Upload media

Files:

- camera_screen.dart

Status:

Not started

---

## Phase 11 — Journey Monitoring

Goal:

Allow family/friends to monitor ongoing journeys.

Features:

- Remaining time
- Last location
- Journey active state
- Auto notifications

Status:

Not started

---

## Phase 12 — Safe Route Prediction

Goal:

Suggest safer routes.

Features:

- Crime heatmap
- Risk score
- Safer alternatives

Status:

Planned

---

## Phase 13 — AI Risk Detection

Goal:

Predict unsafe situations.

Features:

- ML model
- Risk prediction
- Context awareness

Status:

Planned

---

# Development Rules

1. Work one step at a time.

2. Never modify multiple modules together.

3. Build → Integrate → Test → Proceed.

4. Always provide full updated code for changed files.

5. Avoid temporary hacks unless used for testing.

6. Maintain production-quality architecture.

7. Reuse services instead of duplicating logic.

8. Preserve backward compatibility.

9. Test every feature on real mobile devices.

10. Commit after every stable milestone.

---

# Git Commit Strategy

One feature = One commit.

Examples:

feat(auth): firebase login and signup

feat(sos): implement active alert creation

feat(assist): add volunteer feed

feat(rescue): add google maps live tracking

feat(nav): launch external google maps navigation

feat(timer): implement journey timer with auto SOS

---

# Next Immediate Task

Phase 9

Trusted Contacts Module

Implement:

- Add contact
- Save to Firestore
- View contacts
- Edit contacts
- Delete contacts
- Emergency call and SMS support