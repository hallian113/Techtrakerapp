import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tech_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login Function
  Future<TechModel?> login(String email, String password) async {
    try {
      // 1. Firebase Auth se login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      print("Auth Success! UID: $uid");

      // 2. Firestore se user ki details aur role get karna
      DocumentSnapshot doc = await _db.collection('technicians').doc(uid).get();

      if (doc.exists) {
        print("Firestore Document Found!");
        return TechModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        print("ERROR: Firestore mein is UID ($uid) ka document nahi mila!");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      // Agar email/password galat hai toh yahan aayega
      print("FirebaseAuth Error: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("General Error: $e");
      return null;
    }
  }

  // Logout Function
  Future<void> logout() async {
    await _auth.signOut();
  }
}
