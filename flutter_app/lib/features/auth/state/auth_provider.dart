import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/shared/services/api_service.dart';
import 'package:flutter_app/shared/models/user.dart' as app_user;

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _firebaseUser;
  app_user.User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  app_user.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _getUserInfo();
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _getUserInfo() async {
    if (_firebaseUser == null) return;

    try {
      final response = await ApiService().getCurrentUser();
      if (response.success && response.data != null) {
        _user = app_user.User.fromJson(response.data['user']);
      }
    } catch (e) {
      print('Failed to get user info: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = '登录失败，请稍后重试';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password, String nickname) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      _firebaseUser = userCredential.user;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = '注册失败，请稍后重试';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _firebaseUser = null;
    _user = null;
    notifyListeners();
  }

  static AuthProvider of(BuildContext context) {
    return Provider.of<AuthProvider>(context, listen: false);
  }
}
