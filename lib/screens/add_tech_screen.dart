import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../widgets/custom_button.dart';

class AddTechScreen extends StatefulWidget {
  const AddTechScreen({super.key});

  @override
  State<AddTechScreen> createState() => _AddTechScreenState();
}

class _AddTechScreenState extends State<AddTechScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Tech create karne ka function
  Future<void> _createTechAccount() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields. Password must be 6+ chars."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Secondary Firebase App initialize karna (Taake Admin logout na ho)
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Naya user create karna secondary app ke zariye
      UserCredential userCredential = await FirebaseAuth.instanceFor(
        app: secondaryApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      // 3. Firestore mein tech ki details save karna
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name,
            'email': email,
            'role': 'tech', // Role Tech set kar rahe hain
            'isPunchedIn': false,
            'currentLat': 0.0,
            'currentLng': 0.0,
            'currentAddress': 'Not tracked yet',
            'currentStatus': 'Off Duty',
          });

      // 4. Secondary app ko band kar dena
      await secondaryApp.delete();

      setState(() {
        _isLoading = false;
      });

      // 5. Success message aur wapas admin dashboard par jana
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tech '$name' added successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Wapis Admin Dashboard par
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Technician')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_add,
                  size: 80,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(height: 30),

                // Name Field
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tech Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),

                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tech Email',
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
                    labelText: 'Password (Min 6 characters)',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 40),

                // Create Button
                CustomButton(
                  text: 'CREATE TECH ACCOUNT',
                  onPressed: _createTechAccount,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
