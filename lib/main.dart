import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/people_screen.dart';
import 'screens/person_form_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'models/user_model.dart';
import 'models/person_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'People Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/dashboard': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as UserModel;
          return DashboardScreen(user: user);
        },
        '/profile': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as UserModel;
          return ProfileScreen(user: user);
        },
        '/people': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as UserModel;
          return PeopleScreen(user: user);
        },
        '/person-form': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map<String, dynamic>) {
            final user = args['user'] as UserModel?;
            final person = args['person'] as PersonModel?;
            if (user == null) {
              return const Scaffold(
                body: Center(child: Text('Error: User not found')),
              );
            }
            return PersonFormScreen(
              person: person,
              user: user,
            );
          }
          return const Scaffold(
            body: Center(child: Text('Error: Invalid arguments')),
          );
        },
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const AuthScreen();
        }

        // User is signed in, check if profile exists
        return FutureBuilder<bool>(
          future: _firestoreService.userExists(user.uid),
          builder: (context, userExistsSnapshot) {
            if (userExistsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userExists = userExistsSnapshot.data ?? false;

            if (!userExists) {
              // Show onboarding
              return OnboardingScreen(
                uid: user.uid,
                displayName: user.displayName,
                email: user.email,
              );
            }

            // User exists, show dashboard
            return StreamBuilder<UserModel?>(
              stream: _firestoreService.getUserStream(user.uid),
              builder: (context, userModelSnapshot) {
                if (userModelSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final userModel = userModelSnapshot.data;

                if (userModel == null) {
                  return const Scaffold(
                    body: Center(child: Text('Error loading user data')),
                  );
                }

                return DashboardScreen(user: userModel);
              },
            );
          },
        );
      },
    );
  }
}
