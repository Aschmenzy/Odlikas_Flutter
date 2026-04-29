# Odlikaš Mobile

Flutter app for Croatian students — a companion for the national e-grade system [E-Dnevnik](https://ocjene.skole.hr). Pulls grades, tests, and absences from the portal, sends push notifications on grade drops, and adds tools for studying and tracking academic progress.

**Backend:** [E-Dnevnik API](https://github.com/Karlo11111/E_Dnevnik_API) — `https://e-dnevnik-api.fly.dev`

---

## Features

- Grade overview across all subjects, with per-subject detail and grade history
- Absence tracking
- Upcoming test schedule
- Push notifications on new grades and tests (FCM)
- Pending tasks — AI-generated study tasks based on upcoming tests
- Leaderboard — opt-in anonymous GPA ranking by school program
- Pomodoro timer with daily streak tracking
- AI chatbot powered by OpenAI
- Screen sharing — connect to tablet view for extended display
- File upload and PDF viewer for Odlikaš+ users
- Dyslexia mode — app-wide font switch for accessibility
- Odlikaš+ premium tier via Stripe (€10/month) — subscription management and cancellation

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter (Dart) |
| State management | Provider + ChangeNotifier |
| HTTP client | Dio with Bearer token auth + auto-refresh interceptor |
| Auth storage | flutter_secure_storage (JWT) |
| Local cache | Hive |
| Push notifications | Firebase Cloud Messaging |
| Cloud database | Cloud Firestore |
| File storage | Firebase Storage |
| Payments | flutter_stripe (Stripe.js v3) |
| AI | OpenAI API |
| Root detection | safe_device |

---

## Project Structure

```
odlikas_mobilna/
├── lib/
│   ├── main.dart                        # App entry point, routing, Provider setup, startup token check
│   ├── customBottomNavBar.dart          # Shared bottom navigation bar
│   ├── font_service.dart                # Dynamic font switching (dyslexia mode)
│   ├── constants/                       # App-wide color and style constants
│   ├── database/
│   │   ├── api/                         # Dio client, auth interceptor, token storage, login/logout
│   │   ├── models/                      # Data models (grades, schedule, tests, viewmodels)
│   │   └── firebase_options.dart
│   ├── services/
│   │   ├── payment_service.dart         # Stripe: create subscription, confirm, cancel
│   │   └── ...                          # Account, leaderboard, pomodoro, study notifications
│   └── pages/
│       ├── HomePage/                    # Dashboard — grade cards, schedule, calendar
│       ├── SubjectsPage/                # Subject list
│       ├── SpecificSubjectPage/         # Per-subject grades and notes
│       ├── LeaderboardPage/             # Anonymous GPA leaderboard
│       ├── PomodoroPage/                # Study timer with streak
│       ├── PendingTasksPage/            # AI-generated study tasks
│       ├── AiChatbotPage/               # In-app AI assistant
│       ├── PaywallPage/                 # Odlikaš+ paywall, payment sheet, subscription management
│       ├── NotificationsPage/           # Push notification history
│       ├── newNotifications/            # Notification detail view
│       ├── ConnectToScreenPage/         # Tablet screen pairing flow
│       ├── UploadFilesOdlikasPlus/      # PDF upload and viewer (Odlikaš+ only)
│       ├── SettingsPages/               # App settings, accessibility, subscription status
│       ├── ProfilePage/                 # Student profile
│       ├── SchedulePage/                # Weekly timetable editor
│       ├── CalendarPage/                # Personal calendar with custom events
│       └── ...
├── assets/
│   ├── images/
│   ├── icon/
│   └── animations/
└── android/
    └── app/src/main/res/
        ├── values/styles.xml            # Theme.AppCompat (required by flutter_stripe)
        └── values-night/styles.xml      # Dark mode variant
```

---

## Running Locally

### Prerequisites

- Flutter SDK `>=3.6.1`
- Android Studio or VS Code with Flutter extension
- Physical Android device (API 23+) or emulator
- Access to the Odlikaš backend API

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/Aschmenzy/Odlikas_Flutter.git
   cd Odlikas_Flutter/odlikas_mobilna
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a `.env` file in `odlikas_mobilna/` (next to `pubspec.yaml`):
   ```env
   BASE_URL=http://<backend-ip>:<port>
   OPEN_AI_KEY=your_openai_api_key
   STRIPE_PUBLISHABLE_KEY=pk_test_...
   ```

   > `.env` is listed in `.gitignore` and must never be committed.

4. Add Firebase config — `google-services.json` (Android) is required for FCM and Firestore. Contact a team member — it is not stored in the repo.

5. Run:
   ```bash
   flutter run
   ```

### Environment Variables

| Variable | Description |
|---|---|
| `BASE_URL` | Base URL of the Odlikaš ASP.NET backend API |
| `OPEN_AI_KEY` | OpenAI API key for the AI chatbot |
| `STRIPE_PUBLISHABLE_KEY` | Stripe publishable key for the payment sheet |

---

## Authentication Flow

1. User enters E-Dnevnik credentials on the login screen
2. `LoginService` exchanges them for a session token via the backend
3. Token is stored in encrypted secure storage (`flutter_secure_storage`)
4. `AuthInterceptor` (Dio) attaches the token to every request and transparently retries on `401`
5. On startup, `StartupRouter` checks for a valid token and routes to `HomePage` or the login screen

---

## Odlikaš+ (Premium)

Stripe test mode. Card `4242 4242 4242 4242` triggers a real payment sheet flow without charging.

| Feature | Free | Odlikaš+ |
|---|---|---|
| Grade overview | Yes | Yes |
| Notifications | 1 subject | Up to 5 subjects |
| AI chatbot | Limited | Unlimited |
| Tablet screen sync | No | Yes |
| PDF file upload | No | Yes |
| Pomodoro sync | No | Yes |

Subscription management (view status, cancel) is in **Settings → Odlikaš+**.

---

## Security

- Credentials are never stored — only a session token is kept, in encrypted secure storage
- All secrets loaded from `.env` at runtime — nothing hardcoded
- Root/jailbreak detection via `safe_device` (non-blocking warning)
- Android theme set to `Theme.AppCompat` in both light and dark variants (required by flutter_stripe)
