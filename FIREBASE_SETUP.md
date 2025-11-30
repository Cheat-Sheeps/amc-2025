# Firebase Storage CORS Fix

## The Problem
Your uploaded images can't be loaded in the browser due to CORS (Cross-Origin Resource Sharing) restrictions.

## The Solution
You need to update your Firebase Storage Rules to allow public read access.

## Steps to Fix:

### 1. Go to Firebase Storage Rules
Open this URL in your browser:
https://console.firebase.google.com/project/amc-2025/storage/amc-2025.firebasestorage.app/rules

### 2. Replace the entire rules content with:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 3. Click "Publish" button

### 4. Wait 1-2 minutes for changes to propagate

### 5. Hard refresh your app (Cmd+Shift+R on Chrome)

---

## What this does:
- `allow read: if true;` - Anyone can read/view your uploaded images
- `allow write: if request.auth != null;` - Only authenticated users can upload

This is safe for your hackathon demo!
