import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    try {
      _currentUser = await _authService.getCurrentUserModel();
    } catch (_) {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signIn(email: email, password: password);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signInWithGoogle();
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    List<String>? subjects,
    String? photoUrl,
    bool removePhotoUrl = false,
  }) async {
    if (_currentUser == null) return;
    try {
      await _authService.updateUserProfile(
        uid: _currentUser!.uid,
        displayName: displayName,
        bio: bio,
        subjects: subjects,
        photoUrl: removePhotoUrl ? null : photoUrl,
        removePhotoUrl: removePhotoUrl,
      );
      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        bio: bio,
        subjects: subjects,
        photoUrl: removePhotoUrl ? null : photoUrl,
        clearPhotoUrl: removePhotoUrl,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> deleteAccount() async {
    _setLoading(true);
    try {
      await _authService.deleteAccount();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword(String newPassword) async {
    _setLoading(true);
    try {
      await _authService.changePassword(newPassword);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  AuthService get authService => _authService;

  void clearError() => _clearError();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
