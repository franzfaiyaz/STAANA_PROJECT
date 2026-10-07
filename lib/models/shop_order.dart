import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctadmobl_project/models/cart_item.dart';

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.uid,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
  });

  final String id;
  final String uid;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;
  final String status;
  final String paymentMethod;
  final String shippingAddress;

  factory ShopOrder.fromDocument(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return ShopOrder(
      id: id,
      uid: map['uid'] as String? ?? '',
      items: (map['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromMap)
          .toList(),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse('$createdAt') ?? DateTime.now(),
      status: map['status'] as String? ?? 'Unknown',
      paymentMethod: map['paymentMethod'] as String? ?? 'Unknown',
      shippingAddress: map['shippingAddress'] as String? ?? '',
    );
  }
}
