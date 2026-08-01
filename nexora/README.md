# Nexora — The Next Generation of Connected Communities

A premium, production-quality **Flutter frontend** for Nexora: a trust-first social
platform inspired by Instagram, Threads and X. Every screen is fully navigable,
styled with Material You + glassmorphism, and backed by realistic mock data so the
UI is ready to be wired to a real backend.

## Stack

| Concern        | Choice                                   |
| -------------- | ---------------------------------------- |
| Language       | Dart (Flutter latest stable)             |
| UI             | Material 3, Material You theming         |
| State          | Riverpod (Notifier / Provider)           |
| Navigation     | GoRouter (StatefulShellRoute + tabs)     |
| Architecture   | Clean Architecture + MVVM (feature-first)|

## Run it

```bash
flutter pub get
flutter run
```

> No API keys needed — all data comes from `lib/features/*/data/mock_data.dart`.
> Swap the mock repositories for real HTTP calls through `core/network/api_client.dart`
> when your backend is ready.

## Project structure

```
lib/
├── main.dart                 # Entry point (ProviderScope)
├── app/
│   ├── app.dart              # MaterialApp.router + themes
│   ├── router/               # GoRouter configuration
│   └── theme/                # Material You colors, typography, theme mode
├── core/
│   ├── constants/            # Strings / app constants
│   ├── models/               # Shared domain models (User, TrustLabel)
│   ├── network/              # ApiClient stub (ready for backend)
│   └── utils/                # Formatters
├── shared/
│   └── widgets/              # Reusable UI: trust gauge, glass cards, skeletons…
├── navigation/
│   └── main_shell.dart       # Bottom-nav shell (Home, Explore, Create, Reels, Profile)
└── features/
    ├── auth/                 # Splash, Onboarding, Login, Register, Age verification
    ├── feed/                 # Home feed: stories, posts, carousel, video, comments
    ├── explore/              # Discover grid + trending topics
    ├── search/               # People / posts / hashtags search
    ├── create_post/          # Media picker, caption, hashtags, mentions, location
    ├── reels/                # Full-screen vertical video player
    ├── notifications/        # Activity feed with Trust tab
    ├── chat/                 # Conversation list + chat detail
    ├── profile/              # Profile, edit profile, saved, achievements
    ├── settings/             # Appearance, privacy, about, sign out
    ├── trust_center/         # Trust Score gauge, history, factors
    ├── moderator/            # Mod queue + moderation actions
    └── admin/                # Platform analytics + user management
```

Each feature follows the same shape:

```
feature/
├── data/           # models, mock data, repositories (backend-ready)
└── presentation/   # Riverpod providers (MVVM view-models) + screens + widgets
```

## Trust System

Nexora's signature feature: every member carries a **Trust Score (0–100)** and a
**color-coded Trust Label** shown across the app:

| Label       | Color    | Meaning                                |
| ----------- | -------- | -------------------------------------- |
| Verified    | 🟢 Green  | Fully verified identity & history      |
| Vetted      | 🔵 Blue   | Vetted by community moderators         |
| Premium     | 🟣 Purple | Premium creator                        |
| Watch       | 🟠 Orange | Under review                           |
| Restricted  | 🔴 Red    | Limited privileges                     |
