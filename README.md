# Flutter Firebase People Manager App

A Flutter application with Firebase integration featuring Google Sign-In, Firestore for data storage, and Firebase Storage for photo management. The app includes user onboarding, profile management, and people management with a 150-person limit enforced both client-side and server-side.

## Features

- **Google Sign-In**: Secure authentication using Firebase Auth and Google Sign-In
- **User Onboarding**: First-time user setup with profile information
- **Profile Management**: Edit user profile including photo upload
- **People Management**: Add, view, edit, and delete up to 150 people
- **Photo Storage**: Profile and people photos stored in Firebase Storage
- **Validation**: Phone format, date of birth (>=13 years), and photo validation (JPG/PNG, ≤5MB)
- **Limit Enforcement**: 150-person limit enforced via Firestore transactions and Cloud Functions
- **Security Rules**: User-specific access control for Firestore and Storage

## Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Firebase project with:
  - Authentication enabled (Google Sign-In provider)
  - Firestore Database
  - Firebase Storage
  - Cloud Functions (for server-side limit enforcement)
- Android Studio / Xcode for mobile development
- Node.js (for Cloud Functions deployment)

## Firebase Console Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Follow the setup wizard

### 2. Enable Authentication

1. Navigate to **Authentication** > **Sign-in method**
2. Enable **Google** sign-in provider
3. Add your app's SHA-1 fingerprint (for Android):
   - Run: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - Copy SHA-1 and add to Firebase Console > Project Settings > Your Android App

### 3. Create Firestore Database

1. Navigate to **Firestore Database**
2. Click "Create database"
3. Start in **test mode** (we'll update rules)
4. Choose your preferred location

### 4. Create Firebase Storage

1. Navigate to **Storage**
2. Click "Get started"
3. Start in **test mode** (we'll update rules)
4. Choose your preferred location

### 5. Deploy Security Rules

Deploy the security rules to Firebase:

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules
```

### 6. Setup Cloud Functions

1. Install Firebase CLI if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Functions (if not already done):
   ```bash
   cd my_app
   firebase init functions
   ```

4. Install dependencies:
   ```bash
   cd functions
   npm install
   ```

5. Deploy the function:
   ```bash
   firebase deploy --only functions
   ```

### 7. Configure iOS (if targeting iOS)

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `ios/Runner/` in Xcode
3. Ensure the file is added to the Runner target

### 8. Configure Android

The `google-services.json` file should already be in `android/app/`. If not:
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`

## Installation & Running

### 1. Install Dependencies

```bash
cd my_app
flutter pub get
```

### 2. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run

# For specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

## Project Structure

```
my_app/
├── lib/
│   ├── main.dart                 # App entry point with auth state management
│   ├── models/
│   │   ├── user_model.dart       # User data model
│   │   └── person_model.dart     # Person data model
│   ├── services/
│   │   ├── auth_service.dart     # Google Sign-In and auth management
│   │   ├── firestore_service.dart # Firestore operations with transactions
│   │   └── storage_service.dart  # Photo upload/download with progress
│   ├── screens/
│   │   ├── auth_screen.dart      # Google Sign-In screen
│   │   ├── onboarding_screen.dart # First-time user setup
│   │   ├── dashboard_screen.dart # Main dashboard
│   │   ├── profile_screen.dart   # Edit user profile
│   │   ├── people_screen.dart   # List of people
│   │   └── person_form_screen.dart # Add/edit person form
│   ├── widgets/
│   │   ├── photo_picker_widget.dart # Photo selection widget
│   │   └── upload_progress_widget.dart # Upload progress indicator
│   └── utils/
│       └── validators.dart       # Validation utilities
├── functions/
│   ├── index.js                  # Cloud Function for limit enforcement
│   └── package.json              # Functions dependencies
├── firestore.rules              # Firestore security rules
└── storage.rules                # Storage security rules
```

## Key Code Snippets

### Firebase Initialization

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### Google Sign-In Flow

```dart
// lib/services/auth_service.dart
Future<UserCredential?> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  if (googleUser == null) return null;
  
  final GoogleSignInAuthentication googleAuth = 
      await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  
  return await _auth.signInWithCredential(credential);
}
```

### Firestore Transaction for 150-Person Limit

```dart
// lib/services/firestore_service.dart
Future<String> addPerson(String uid, PersonModel person) async {
  return await _firestore.runTransaction((transaction) async {
    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await transaction.get(userRef);
    
    if (!userDoc.exists) {
      throw Exception('User document does not exist');
    }
    
    final userData = userDoc.data()!;
    final currentCount = (userData['peopleCount'] as int?) ?? 0;
    
    // Check if limit is reached
    if (currentCount >= 150) {
      throw Exception('Maximum limit of 150 people reached');
    }
    
    // Create person document reference
    final personRef = userRef.collection('people').doc();
    
    // Increment peopleCount and create person atomically
    transaction.update(userRef, {
      'peopleCount': currentCount + 1,
    });
    
    transaction.set(personRef, person.toFirestore());
    
    return personRef.id;
  });
}
```

### Photo Upload with Progress

```dart
// lib/services/storage_service.dart
UploadTask uploadProfilePhotoWithProgress(File photoFile) {
  final user = _auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  final ref = _storage.ref()
      .child('profilePhotos/${user.uid}/profile.jpg');
  return ref.putFile(photoFile);
}

// Usage in widget:
StreamBuilder<TaskSnapshot>(
  stream: uploadTask.snapshotEvents,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final progress = snapshot.data!.bytesTransferred / 
                      snapshot.data!.totalBytes;
      return LinearProgressIndicator(value: progress);
    }
    return const SizedBox.shrink();
  },
)
```

### Cloud Function for Server-Side Enforcement

```javascript
// functions/index.js
exports.enforcePeopleLimit = functions.firestore
  .document('users/{userId}/people/{personId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const userRef = admin.firestore().collection('users').doc(userId);
    const userDoc = await userRef.get();
    
    const currentCount = userDoc.data().peopleCount || 0;
    
    if (currentCount >= 150) {
      // Delete the person document
      await snap.ref.delete();
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Maximum limit of 150 people reached'
      );
    }
  });
```

## Security Rules

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                               request.auth.uid == userId;
      
      match /people/{personId} {
        allow read, write: if request.auth != null && 
                                 request.auth.uid == userId;
      }
    }
  }
}
```

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profilePhotos/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && 
                               request.auth.uid == userId;
    }
    
    match /peoplePhotos/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && 
                               request.auth.uid == userId;
    }
  }
}
```

## Data Structure

### User Document (`users/{uid}`)

```json
{
  "name": "John Doe",
  "phone": "+1234567890",
  "dateOfBirth": "1990-01-01T00:00:00Z",
  "photoUrl": "https://...",
  "peopleCount": 5
}
```

### Person Document (`users/{uid}/people/{personId}`)

```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "phone": "+1234567890",
  "dateOfBirth": "1995-05-15T00:00:00Z",
  "photoUrl": "https://..."
}
```

## Validation Rules

- **Phone**: Flexible format, accepts 7-15 digits with optional country code
- **Date of Birth**: Must be at least 13 years old, cannot be in the future
- **Photo**: JPG or PNG format only, maximum 5MB file size
- **Email**: Standard email format validation
- **Name**: Minimum 2 characters

## Troubleshooting

### Google Sign-In Issues

- Ensure SHA-1 fingerprint is added to Firebase Console
- Check that Google Sign-In is enabled in Firebase Authentication
- Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is correctly configured

### Photo Upload Issues

- Check Storage security rules are deployed
- Verify file size is under 5MB
- Ensure file format is JPG or PNG

### Firestore Permission Errors

- Verify Firestore security rules are deployed
- Check that user is authenticated
- Ensure user document exists before accessing people collection

### Cloud Function Not Triggering

- Verify function is deployed: `firebase functions:list`
- Check function logs: `firebase functions:log`
- Ensure Firestore trigger path matches: `users/{userId}/people/{personId}`

## License

This project is provided as-is for educational purposes.
