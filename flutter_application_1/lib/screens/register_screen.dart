import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/widgets/custom_textfield.dart';
import 'package:tracking_app/widgets/custom_button.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _selectedRole = 'tech';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.black, AppTheme.blackLight],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🥇 Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: const Icon(
                          Icons.person_add,
                          color: AppTheme.black,
                          size: 35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create New Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a new user to the system',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 👤 Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter full name',
                  prefixIcon: Icons.person,
                ),

                const SizedBox(height: 16),

                // 📧 Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // 🔒 Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter password (min 6 chars)',
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

                const SizedBox(height: 16),

                // 🔒 Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.greyMedium,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // 🎯 Role Selection
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.blackCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.gold.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'tech';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'tech'
                                  ? AppTheme.gold
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Technician',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole == 'tech'
                                    ? AppTheme.black
                                    : AppTheme.greyLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'admin';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'admin'
                                  ? AppTheme.gold
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Administrator',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole == 'admin'
                                    ? AppTheme.black
                                    : AppTheme.greyLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🚀 Register Button
                CustomButton(
                  text:
                      authProvider.isLoading ? 'Creating...' : 'CREATE ACCOUNT',
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          // Validation
                          if (_nameController.text.isEmpty ||
                              _emailController.text.isEmpty ||
                              _passwordController.text.isEmpty) {
                            Fluttertoast.showToast(
                              msg: 'Please fill all fields',
                              backgroundColor: AppTheme.error,
                            );
                            return;
                          }

                          if (_passwordController.text.length < 6) {
                            Fluttertoast.showToast(
                              msg: 'Password must be at least 6 characters',
                              backgroundColor: AppTheme.error,
                            );
                            return;
                          }

                          if (_passwordController.text !=
                              _confirmPasswordController.text) {
                            Fluttertoast.showToast(
                              msg: 'Passwords do not match',
                              backgroundColor: AppTheme.error,
                            );
                            return;
                          }

                          bool success = await authProvider.register(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                            _nameController.text.trim(),
                            _selectedRole,
                          );

                          if (success && mounted) {
                            _nameController.clear();
                            _emailController.clear();
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                            Navigator.pop(context);
                          }
                        },
                ),

                const SizedBox(height: 16),

                // 🔙 Back to Login
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: AppTheme.greyLight,
                        fontSize: 14,
                      ),
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
