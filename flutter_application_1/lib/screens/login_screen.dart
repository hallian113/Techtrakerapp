import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/widgets/custom_textfield.dart';
import 'package:tracking_app/widgets/custom_button.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.black,
              AppTheme.blackLight,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // 🥇 Premium Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppTheme.black,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.goldGradient.createShader(bounds),
                      child: const Text(
                        'TechTracker',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // 👋 Welcome Text
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to continue tracking your workforce',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.greyLight,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 40),

                // 📧 Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // 🔒 Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.greyMedium,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // 🔑 Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Fluttertoast.showToast(
                        msg: 'Contact admin to reset password',
                        backgroundColor: AppTheme.gold,
                        textColor: AppTheme.black,
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 🚀 Login Button
                CustomButton(
                  text: authProvider.isLoading ? 'Logging in...' : 'LOGIN',
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_emailController.text.isEmpty ||
                              _passwordController.text.isEmpty) {
                            Fluttertoast.showToast(
                              msg: 'Please fill all fields',
                              backgroundColor: AppTheme.error,
                            );
                            return;
                          }

                          bool success = await authProvider.login(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          );

                          if (success && mounted) {
                            if (authProvider.isAdmin) {
                              Navigator.pushReplacementNamed(context, '/admin');
                            } else {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          }
                        },
                ),

                const SizedBox(height: 20),

                // 📝 Register Hint
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: AppTheme.greyLight,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Fluttertoast.showToast(
                            msg: 'Contact admin to create account',
                            backgroundColor: AppTheme.gold,
                            textColor: AppTheme.black,
                          );
                        },
                        child: Text(
                          'Contact Admin',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 🥇 Decorative Line
                Center(
                  child: Container(
                    width: 80,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
