# EduBook Flutter (منصة المنارة التعليمية)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--Driven%20Clean%20Architecture-teal?style=for-the-badge)](#architecture)
[![State Management](https://img.shields.io/badge/State-Riverpod%202.x-purple?style=for-the-badge)](#state-management)

A production-ready cross-platform educational platform developed in Flutter, tailored to Omani educational standards. It provides interactive digital textbook reading, multi-tier user role management (Students, Teachers, Admins), course enrollment, and bank slip payment workflows.

---

## 📱 Features Overview

### 🔐 Authentication & Onboarding
- **Role-based Registration**: Supports both **Student** (with grade level assignment) and **Teacher** roles.
- **Secure Token Management**: JWT authentication with refresh token lifecycle managed through `flutter_secure_storage`.
- **OTP Verification & Password Recovery**: Full email OTP verification flow for account activation and password reset.

### 📚 Interactive eBook Reader
- **High-Performance Page Renderer**: Secure on-demand page streaming from the backend.
- **Pinch-to-Zoom & Pan**: Smooth multi-touch inspection via Flutter `InteractiveViewer`.
- **Reading Progress Sync**: Automatically syncs reading progress and bookmarks with the backend.
- **In-Book Annotations**: Add, inspect, and remove notes directly on textbook pages.
- **Free Sample Preview**: Allows prospective students to preview sample book units before purchasing.

### 💳 Order Management & Payments
- **Bank Transfer Checkout**: Submit orders with receipt slip attachments (using `file_picker`).
- **Order Tracking**: Real-time status inspection (Pending, Approved, Rejected) with admin notes.

### 🛠️ Comprehensive Admin Dashboard
- **Book Management**: Create, update, and publish digital curriculum books and units.
- **Category & Grade Management**: Organize textbooks across school grade levels and academic subjects.
- **Order Review**: Verify payment slips and approve/reject student subscriptions.
- **User Management**: Manage roles, account activations, and permissions.

### 🌐 Internationalization & Accessibility
- **Bilingual Support**: Native Arabic (RTL) and English (LTR) localization using Flutter Localization & `intl`.
- **Curated Theme System**: Ministry of Education inspired palette with high contrast and smooth responsive layouts.

---

## 🏗️ Project Architecture

The project adheres to a **Feature-Driven Clean Architecture**:

```
lib/
├── app/
│   ├── router/          # GoRouter configuration & navigation guards
│   └── theme/           # Design system tokens, color palettes, and themes
├── core/
│   ├── network/         # Dio HTTP client, interceptors, error handling
│   ├── storage/         # Secure storage & persistent preferences
│   └── widgets/         # Reusable UI components (buttons, text fields, cards)
├── features/
│   ├── admin/           # Admin management tabs (books, categories, orders, users)
│   ├── auth/            # Login, register, OTP verification, password reset
│   ├── books/           # Book catalogs, grade filters, book details
│   ├── home/            # Dashboard, banners, announcements, quick links
│   ├── orders/          # Checkout, payment slip upload, order tracking
│   ├── profile/         # User profile details and settings
│   ├── reader/          # Interactive eBook reader, progress sync & annotations
│   └── settings/        # Locale and appearance preferences
└── l10n/                # Localization AR / EN arb files and generated delegates
```

---

## ⚙️ Tech Stack & Key Libraries

| Dependency | Purpose |
| :--- | :--- |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | Declarative, compile-safe state management |
| [`go_router`](https://pub.dev/packages/go_router) | Declarative routing, deep-linking, and route guards |
| [`dio`](https://pub.dev/packages/dio) | HTTP client with automatic auth interceptors |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Keychain/Keystore encrypted credentials storage |
| [`file_picker`](https://pub.dev/packages/file_picker) | Document & payment slip attachments |
| [`intl`](https://pub.dev/packages/intl) | Internationalization and RTL/LTR date & text handling |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.9.0` or higher)
- Android Studio / VS Code with Flutter and Dart extensions
- Android SDK (API 34 recommended) or a physical Android device

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Youssef-Ebn-Yasser/EduBook-Flutter.git
   cd EduBook-Flutter
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate localizations:**
   ```bash
   flutter gen-l10n
   ```

4. **Run the application:**
   - **Development / Staging:**
     ```bash
     flutter run --dart-define=ENV=staging
     ```
   - **Production:**
     ```bash
     flutter run --dart-define=ENV=production
     ```

### Building for Release

Generate release APK:
```bash
flutter build apk --release
```

Generate Android App Bundle (AAB):
```bash
flutter build appbundle --release
```

---

## 📄 License
This project is proprietary and confidential. All rights reserved.