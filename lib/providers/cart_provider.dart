import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctadmobl_project/models/cart_item.dart';
import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _uid;
  List<CartItem> _items = [];
  bool _isLoading = false;
  Object? _error;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  Object? get error => _error;
  int get itemCount =>
      _items.fold(0, (itemTotal, item) => itemTotal + item.quantity);
  double get total =>
      _items.fold(0, (amount, item) => amount + item.price * item.quantity);

  void bindUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _listenToCart();
  }

  void reload() {
    if (_uid != null) _listenToCart();
  }

  void _listenToCart() {
    final uid = _uid;
    _items = [];
    _error = null;
    _subscription?.cancel();
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    _subscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .snapshots()
        .listen(
          (snapshot) {
            _items = snapshot.docs
                .map((doc) => CartItem.fromMap(doc.data()))
                .toList();
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('Unable to load cart: $error');
            _isLoading = false;
            _error = error;
            notifyListeners();
          },
        );
  }

  Future<void> add(CartItem item) async {
    final ref = _cartCollection.doc('${item.productId}_${item.size}');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        final current = CartItem.fromMap(snapshot.data()!);
        transaction.update(ref, {'quantity': current.quantity + item.quantity});
      } else {
        transaction.set(ref, item.toMap());
      }
    });
  }

  Future<void> changeQuantity(CartItem item, int delta) async {
    final ref = _cartCollection.doc('${item.productId}_${item.size}');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final current = CartItem.fromMap(snapshot.data()!);
      final quantity = current.quantity + delta;
      if (quantity <= 0) {
        transaction.delete(ref);
      } else {
        transaction.update(ref, {'quantity': quantity});
      }
    });
  }

  Future<void> remove(CartItem item) {
    return _cartCollection.doc('${item.productId}_${item.size}').delete();
  }

  Future<void> clear() async {
    final snapshot = await _cartCollection.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> get _cartCollection {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to use your cart.');
    return _firestore.collection('users').doc(uid).collection('cart');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
