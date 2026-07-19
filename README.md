# CivicVoice

![Status](https://img.shields.io/badge/Status-Release%20Ready-16A34A)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84)
![Flutter](https://img.shields.io/badge/Flutter-3.x-54C5F8)
![API](https://img.shields.io/badge/API-Production-16A34A)

CivicVoice is a Flutter-based civic issue reporting platform for Ghana. It connects citizens, municipal authorities, maintenance teams, and government agencies through a transparent, accountable digital pipeline — from issue submission to resolution.

The integrated Android application is complete and connected to the production API at [`https://api.civicvoice.eraaxis.com`](https://api.civicvoice.eraaxis.com). The API is hosted on AWS and all application traffic uses HTTPS.

---

## Vision

> To become Ghana's trusted digital platform for reporting, tracking, and resolving civic issues by connecting citizens, municipal authorities, and government agencies through transparent and accountable service delivery.

## Mission

> CivicVoice empowers citizens to report community issues quickly and accurately using mobile technology while enabling municipal authorities and government agencies to manage, track, and resolve those issues through a centralized digital platform.

---

## Project Overview

CivicVoice is developed as a semester project for Mobile Computing & Mobile Application Development. The platform allows citizens to report civic issues including:

- Potholes and damaged roads
- Flooding and blocked drains
- Broken streetlights
- Waste disposal and sanitation issues
- Water leaks
- Damaged public infrastructure

Each report captures location (GPS), photographic evidence, a description, and a category. Reports move through a defined workflow — submission, verification, assignment, progress updates, and resolution — with status visibility for the reporting citizen at every stage.

---

## Technology Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x (Dart) |
| Authentication | Firebase Authentication |
| Backend API | Node.js / Express |
| Database | PostgreSQL / Prisma |
| API Hosting | AWS VM (`api.civicvoice.eraaxis.com`) |
| File Uploads | Backend-managed report and profile uploads |
| Push Notifications | Firebase Cloud Messaging |
| Location Services | Geolocator |
| Maps | Google Maps Flutter |
| Design & Prototyping | Figma / Stitch |
| Version Control | GitHub |

---

## Design System

The application is built on the **Civic Glass** design language — a custom system that draws from Apple HIG, Microsoft Fluent, Material 3, Linear, Vercel, and Government UX Principles. It is optimised for readability, accessibility, and civic trust.

- **Accessibility target:** WCAG 2.2 AA minimum, AAA as goal
- **Responsive breakpoints:** 320px · 375px · 428px · 768px

---

## User Roles

| Role | Description |
|---|---|
| Guest Citizen | Reports issues without registration (CR-001) |
| Registered Citizen | Full reporting, tracking, and profile management |
| Municipal Officer | Reviews, verifies, and assigns incoming reports |
| Maintenance Team | Receives task assignments and submits resolution evidence |
| Ministry Supervisor | Views aggregated analytics and regional performance reports |
| System Administrator | System-wide user management, account provisioning, and role assignment |

---

## Modules

All six modules have been integrated into the release application.

### Issue 01 — Authentication & Profile
Splash, Welcome, Login, Registration, Forgot Password, and Profile screens. Only Citizens self-register; all other roles are provisioned by an Admin.

### Issue 02 — Citizen Reporting
Dashboard, Create Report, Category Selection, Location Selection, Photo Upload, Preview, Success, My Reports, and Report Details screens. Supports guest reporting without prior registration.

### Issue 03 — Municipal Officer Module
Dashboard, Incoming Reports, Report Review, Verify/Reject, Assign Team, Active Reports, Report Progress, Resolved Reports, and Profile screens. Includes full audit logging. Citizen contact information is accessible only to Officers.

### Issue 04 — Maintenance Team Module
Dashboard, Assigned Tasks, Task Details, Update Progress, Upload Evidence, Task Completed, and Profile screens. Photo evidence is required before a task can be marked complete. Citizen PII is not visible to this role.

### Issue 05 — Ministry Supervisor Module
Analytics Overview, Regional Breakdown, Category Trends, Response Time Reports, Export Data, and Ministry Profile screens. This role sees aggregated data only — no citizen PII is accessible.

### Issue 06 — System Administrator Module
Admin Dashboard, User Management, Create Account, Edit Account, Deactivate Account, Role Assignment, Audit Log, and Admin Profile screens. All non-citizen accounts (Municipal Officer, Maintenance Team, Ministry Supervisor) are provisioned by this role.

---

## Repository Structure

```text
civic_voice/
├── lib/
│   ├── core/
│   │   ├── constants/          # App-wide constants and enums
│   │   ├── routes/             # Route definitions and navigation
│   │   └── theme/              # Civic Glass theme tokens and styles
│   ├── features/               # Feature-first modules
│   │   ├── authentication/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── models/
│   │   │   └── services/
│   │   ├── reporting/          # Citizen reporting module
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── models/
│   │   │   └── services/
│   │   ├── municipal/          # Municipal officer module
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── models/
│   │   │   └── services/
│   │   ├── maintenance/        # Maintenance team module
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── models/
│   │   │   └── services/
│   │   ├── ministry/           # Ministry oversight module
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── models/
│   │   │   └── services/
│   │   └── admin/              # System administration module
│   │       ├── screens/
│   │       ├── widgets/
│   │       ├── models/
│   │       └── services/
│   ├── models/                 # Shared data models
│   ├── services/               # Shared Firebase and platform services
│   ├── shared/                 # Shared UI components
│   ├── utils/                  # Utility functions and helpers
│   ├── widgets/                # Global reusable widgets
│   └── main.dart
├── assets/
│   ├── fonts/
│   ├── icons/
│   └── images/
├── test/
└── android/
```

---

## Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Stable, reviewed releases only |
| `test` | Integration and QA testing |
| `feature/*` | Individual feature development |

**Workflow:** Feature work is developed on a `feature/*` branch, merged into `test` for integration testing, then promoted to `main` after review and successful automated checks. Release APKs are built from `main`.

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x ([install guide](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code with Flutter extension
- Access to the configured Firebase project
- Google Maps API key

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/<org>/civic_voice.git
   cd civic_voice
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Add your Firebase configuration file:
   - `android/app/google-services.json`

4. Add `GOOGLE_MAPS_API_KEY=<key>` to `android/local.properties`, export it as an environment variable, or pass it with `--dart-define`.

5. Run the application:
   ```bash
   flutter run
   ```

The production API URL is built in. To target another backend during development, override it explicitly:

```bash
flutter run --dart-define=API_BASE_URL=http://<host>:<port>
```

### Build the Android APK

Build release artifacts from `main` only:

```bash
git switch main
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The generated APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

---

## Contributing

1. Check out a new branch from `test`: `git checkout -b feature/<your-feature> test`
2. Implement your changes following the feature-first folder structure under `lib/features/`.
3. Open a pull request targeting the `test` branch — never target `main` directly.
4. At least one reviewer must approve before merging.

---

## Authors

- Hassan Abdul Aziz ([@khakho3](https://github.com/khakho3))
- Francis Afun Kekeli ([@FranzAfun](https://github.com/FranzAfun))
- Abdul Latif Osman Sani ([@latifsani7](https://github.com/latifsani7))
- Kingsben Ofosu Amoako ([@Kingsben](https://github.com/Kingsben))
- Anorful Kingsley ([@kingsley-anord](https://github.com/kingsley-anord))

---

## License

This project was developed as part of a university coursework project.
