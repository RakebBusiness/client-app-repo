import 'package:flutter/material.dart';
import '../screens/authentification/login_screen.dart';
import '../screens/otp/otp_screen.dart';
import '../screens/authentification/signup_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const WelcomeScreen(),
  '/otp': (context) => const OtpScreen(),
  '/username': (context) => const UsernameScreen(),
};
