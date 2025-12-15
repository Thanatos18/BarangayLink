import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart'; // Relative import
import 'package:flutter_application_1/screens/main/main_app_screen.dart'; // Relative import to the new Main App wrapper

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. While checking auth state...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If we have a user...
        if (snapshot.hasData) {
          // Navigate to the Main Wrapper (which holds the BottomNavBar + Home)
          return const MainAppScreen();
        }

        // 3. Otherwise, show login
        return const LoginScreen();
      },
    );
  }
}
