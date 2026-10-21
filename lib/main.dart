
import 'package:flutter/material.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/signup_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    ),
  );
}
