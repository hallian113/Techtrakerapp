import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_app/utils/constants.dart';
import 'package:tracking_app/models/user_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tracking_app/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _userRole = AppConstants.roleTech;
  String _userId = '';
  String _userName = '';
  String _userEmail = '';
  UserModel? _userModel;
  bool _isLoading = false;

  User? get user => _user;
  String get userRole => _userRole;
  String get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
      }
      notifyListeners();
    });
  }

  // ✅ Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        _user = user;
        final bool profileLoaded = await _loadUserData(user.uid);
        if (!profileLoaded) {
          await _auth.signOut();
          _setLoading(false);
          Fluttertoast.showToast(
            msg: 'User profile not found. Contact admin.',
          );
          return false;
        }
        await _saveToPreferences();
        await NotificationService().saveTokenForUser(_userId);
        Fluttertoast.showToast(
          msg: 'Welcome back! 🥇',
          backgroundColor: Colors.green,
        );
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      String message = _getAuthErrorMessage(e.code);
      Fluttertoast.showToast(msg: message);
      return false;
    } catch (e) {
      _setLoading(false);
      Fluttertoast.showToast(msg: 'Login failed: $e');
      return false;
    }
  }

  // ✅ Load User Data from Firestore
  Future<bool> _loadUserData(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists && _user?.email != null) {
        final QuerySnapshot<Map<String, dynamic>> matchingUsers =
            await _firestore
                .collection(AppConstants.usersCollection)
                .where('email', isEqualTo: _user!.email!.trim().toLowerCase())
                .limit(1)
                .get();
        if (matchingUsers.docs.isNotEmpty) {
          doc = matchingUsers.docs.first;
        }
      }

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _userRole = (data['role'] ?? '').toString().trim().toLowerCase();
        if (_userRole == 'administrator') {
          _userRole = AppConstants.roleAdmin;
        } else if (_userRole == 'technician') {
          _userRole = AppConstants.roleTech;
        } else if (_userRole != AppConstants.roleAdmin &&
            _userRole != AppConstants.roleTech) {
          return false;
        }
        _userName = data['name'] ?? 'User';
        _userEmail = data['email'] ?? '';
        _userId = uid;
        _userModel = UserModel.fromJson(data, uid);
      } else {
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading user data');
      return false;
    }
  }

  // ✅ Save to SharedPreferences
  Future<void> _saveToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);
    await prefs.setString(AppConstants.prefUserId, _userId);
    await prefs.setString(AppConstants.prefUserEmail, _userEmail);
    await prefs.setString(AppConstants.prefUserName, _userName);
    await prefs.setString(AppConstants.prefUserRole, _userRole);
  }

  // ✅ Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _user = null;
      _userRole = AppConstants.roleTech;
      _userId = '';
      _userName = '';
      _userEmail = '';
      _userModel = null;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Fluttertoast.showToast(msg: 'Logged out successfully');
      notifyListeners();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Logout failed: $e');
    }
  }

  // ✅ Register (Admin will create accounts)
  Future<bool> register(
      String email, String password, String name, String role) async {
    _setLoading(true);
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set({
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        Fluttertoast.showToast(msg: 'Registration successful! 🥇');
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      Fluttertoast.showToast(msg: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      Fluttertoast.showToast(msg: 'Registration failed: $e');
      return false;
    }
  }

  // ✅ Check if user is Admin
  bool get isAdmin => _userRole == AppConstants.roleAdmin;

  // ✅ Auth Error Messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Authentication failed';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
