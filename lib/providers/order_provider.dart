import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctadmobl_project/models/shop_order.dart';
import 'package:flutter/foundation.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ShopOrder>> watchOrders(String uid) {
    return _firestore
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) {
            final orders = snapshot.docs
                .map((doc) => ShopOrder.fromDocument(doc.id, doc.data()))
                .toList();
            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return orders;
          },
        );
  }

  Future<String> createOrder({
    required String uid,
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMethod,
    required String status,
    required String shippingAddress,
  }) async {
    final ref = await _firestore.collection('orders').add({
      'uid': uid,
      'items': items,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status,
      'shippingAddress': shippingAddress,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
