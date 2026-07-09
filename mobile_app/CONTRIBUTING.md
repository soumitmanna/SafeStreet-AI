# Contributing to SafeStreet

Thank you for your interest in contributing to SafeStreet!

This document outlines the project's development workflow, coding standards, and contribution process.

---

# Project Overview

SafeStreet is a Flutter-based emergency response application designed to improve personal safety through:

- Emergency SOS
- Live GPS Tracking
- Trusted Contacts
- Evidence Collection
- Volunteer Assistance
- Real-time Firestore Alerts

---

# Development Environment

## Requirements

- Flutter 3.x
- Dart 3.x
- Android Studio / VS Code / Antigravity IDE
- Firebase CLI
- Git
- Android SDK

---

# Getting Started

Clone the repository

```bash
git clone https://github.com/soumitmanna/SafeStreet.git
```

Navigate to the project

```bash
cd SafeStreet/mobile_app
```

Install dependencies

```bash
flutter pub get
```

Run the application

```bash
flutter run
```

---

# Project Structure

```
lib/
│
├── models/
├── screens/
├── services/
├── utils/
├── widgets/
└── main.dart
```

---

# Coding Guidelines

## Follow Flutter Best Practices

- Use meaningful variable names.
- Prefer composition over inheritance.
- Keep widgets small and reusable.
- Separate UI and business logic.
- Avoid duplicate code.
- Use null safety.
- Keep methods focused on a single responsibility.

---

# Architecture Principles

The project follows a modular architecture.

```
UI
 ↓
Service Layer
 ↓
Firestore
```

Widgets should **never** write directly to Firestore.

All database operations must go through the corresponding service class.

---

# Naming Convention

## Files

```
snake_case.dart
```

Example

```
alert_service.dart
```

---

## Classes

```
PascalCase
```

Example

```
AlertService
```

---

## Variables

```
camelCase
```

Example

```
acceptedAt
```

---

# Git Workflow

Create a new branch

```bash
git checkout -b feature/feature-name
```

Commit changes

```bash
git add .

git commit -m "feat: short description"
```

Push

```bash
git push origin feature/feature-name
```

---

# Commit Message Convention

Feature

```
feat:
```

Bug Fix

```
fix:
```

Refactor

```
refactor:
```

Documentation

```
docs:
```

Style

```
style:
```

Performance

```
perf:
```

Testing

```
test:
```

Examples

```
feat: implement volunteer assistance workflow

fix: correct Firestore status mismatch

refactor: centralize alert creation logic

docs: update project documentation
```

---

# Before Every Commit

Always run

```bash
flutter analyze
```

Then

```bash
flutter test
```

(if tests are available)

Finally

```bash
flutter run
```

Verify

- No crashes
- No new analyzer warnings
- Navigation works
- Firestore updates correctly

---

# Pull Request Checklist

- Code builds successfully
- No analyzer errors
- Feature tested
- UI follows project design
- No duplicate logic
- Documentation updated if necessary

---

# Reporting Issues

When reporting bugs, include

- Flutter version
- Device
- Android version
- Steps to reproduce
- Expected behaviour
- Actual behaviour
- Screenshots (if possible)

---

# Code Review Principles

Every contribution should prioritize

- Readability
- Maintainability
- Performance
- Reusability
- Clean Architecture

---

Thank you for contributing to SafeStreet!

Together we can build a safer community through technology.