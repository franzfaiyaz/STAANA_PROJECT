import 'dart:async';

import 'package:ctadmobl_project/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _subscription = _service.authChanges().listen(
      _loadRole,
      onError: (Object error) {
        debugPrint('Unable to observe authentication state: $error');
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  final AuthService _service;
  StreamSubscription<User?>? _subscription;
  String? _role;
  bool _isLoading = true;
  Object? _error;

  String? get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get isLoading => _isLoading;
  Object? get error => _error;

  void reload() => _loadRole(FirebaseAuth.instance.currentUser);

  Future<void> _loadRole(User? user) async {
    if (user == null) {
      _role = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _role = await _service.getRole(user.uid);
    } catch (error) {
      debugPrint('Unable to load user role: $error');
      _role = null;
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
