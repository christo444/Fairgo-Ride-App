import 'package:fairgo_ride_app/presentation/home_page.dart' show HomePage;
import 'package:fairgo_ride_app/presentation/login_page.dart' show LoginPage;
import 'package:flutter/material.dart';

// The main entry point of the application.
void main() {
  runApp(const RideBookingApp());
}

// The root widget of the application.
class RideBookingApp extends StatelessWidget {
  const RideBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ride Booking App',
      debugShowCheckedModeBanner: false,
      // Define the app's theme for a consistent look and feel.
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F4FF),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F4FF),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
      // Set the initial route to the LoginPage.
      initialRoute: '/',
      // Define the named routes for navigation.
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

