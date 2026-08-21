import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/tech_model.dart';
import '../widgets/custom_button.dart';
import 'tech_dashboard.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    // AuthService call kar ke login karne ki koshish
    TechModel? user = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // Agar user Admin hai toh Admin Dashboard par bhej do
      if (user.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
      } else {
        // Agar Tech hai toh Tech Dashboard par bhej do
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TechDashboard(techId: user.uid, techName: user.name),
          ),
        );
      }
    } else {
      // Agar login fail ho jaye toh error dikhao
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Failed! Check credentials."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background gradient for premium look
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo / Title
                  Icon(
                    Icons.security_update_good,
                    size: 80,
                    color: Color(0xFFD4AF37),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TECHTRACK PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Login Button (Custom Button use kar rahe hain)
                  CustomButton(
                    text: 'LOGIN',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
