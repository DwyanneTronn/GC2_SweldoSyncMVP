import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/payroll_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if user is already authenticated
  final isAuthenticated = await AuthService.isAuthenticated();
  
  runApp(SweldoSyncApp(isAuthenticated: isAuthenticated));
}

class SweldoSyncApp extends StatelessWidget {
  final bool isAuthenticated;

  const SweldoSyncApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SweldoSync MVP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: isAuthenticated
          ? const PayrollHomeScreen()
          : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}