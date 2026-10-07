import 'dart:async';

import 'package:ctadmobl_project/models/user_profile.dart';
import 'package:ctadmobl_project/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._service);

  final AuthService _service;
  UserProfile? _profile;
  bool _isLoading = false;
  Object? _error;
  StreamSubscription<UserProfile?>? _subscription;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  void load(String uid) {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _subscription = _service
        .watchProfile(uid)
        .listen(
          (profile) {
            _profile = profile;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('Unable to load profile: $error');
            _isLoading = false;
            _error = error;
            notifyListeners();
          },
        );
  }

  Future<void> update(String uid, UserProfile profile) async {
    try {
      await _service.updateProfile(uid, profile);
    } catch (error) {
      debugPrint('Unable to save profile: $error');
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
