import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FavoritesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _uid;
  Set<String> _ids = {};
  Object? _error;
  bool _isLoading = false;

  Set<String> get ids => Set.unmodifiable(_ids);
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool contains(String productId) => _ids.contains(productId);

  void bindUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _listenToFavorites();
  }

  void reload() {
    if (_uid != null) _listenToFavorites();
  }

  void _listenToFavorites() {
    _ids = {};
    _error = null;
    _subscription?.cancel();
    if (_uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    _subscription = _collection.snapshots().listen(
      (snapshot) {
        _ids = snapshot.docs.map((doc) => doc.id).toSet();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Unable to load favorites: $error');
        _isLoading = false;
        _error = error;
        notifyListeners();
      },
    );
  }

  Future<void> toggle(String productId) async {
    final ref = _collection.doc(productId);
    if (_ids.contains(productId)) {
      await ref.delete();
    } else {
      await ref.set({'productId': productId});
    }
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to save favorites.');
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
