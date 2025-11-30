# amc

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Bartr (Hackathon) — Quick Start

This workspace includes a basic prototype called **Bartr** — a swipe-focused bartering app backed by Firebase.

### Setup Instructions

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com
   - Create a new project (or use existing one)
   - Enable **Anonymous Authentication** in Authentication > Sign-in method
   - Enable **Firestore Database** in Firestore Database
   - Enable **Firebase Storage** in Storage

2. **Configure FlutterFire**
   ```bash
   # Make sure flutterfire CLI is in your PATH
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   
   # Navigate to app directory
   cd app
   
   # Login to Firebase (if not already)
   firebase login
   
   # Configure FlutterFire for your project
   flutterfire configure
   ```
   
   This will:
   - Prompt you to select your Firebase project
   - Automatically generate `lib/firebase_options.dart` with your config
   - Set up platform-specific Firebase configuration files

3. **Run the App**
   ```bash
   flutter pub get
   flutter run -d chrome  # For web
   # OR
   flutter run            # For connected device
   ```

### App Features

- **Anonymous Sign-in**: Users are automatically signed in anonymously
- **List Items**: Create bartering items with photos and descriptions
- **Swipe Interface**: Swipe right to like, left to pass
- **Mutual Matching**: When two users like each other's items, a match is created
- **Firestore Collections**: `users`, `items`, `likes`, `matches`

### Security Rules (TODO for Production)

Before deploying, add Firestore security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /items/{itemId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.ownerId;
    }
    match /likes/{likeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    match /matches/{matchId} {
      allow read: if request.auth != null && request.auth.uid in resource.data.users;
      allow write: if request.auth != null;
    }
  }
}
```

### Notes
- This is a hackathon prototype — extend features as needed
- Current implementation uses anonymous auth for quick demo
- Match logic creates a `matches` document when mutual likes are detected
