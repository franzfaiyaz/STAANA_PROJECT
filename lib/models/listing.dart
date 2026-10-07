import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.brand,
    required this.category,
    required this.sizes,
    required this.imageBase64,
    required this.status,
    required this.rejectReason,
    required this.createdAt,
  });

  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final double price;
  final String brand;
  final String category;
  final List<int> sizes;
  final String imageBase64;
  final String status;
  final String? rejectReason;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'sellerId': sellerId,
    'sellerName': sellerName,
    'title': title,
    'description': description,
    'price': price,
    'brand': brand,
    'category': category,
    'sizes': sizes,
    'imageBase64': imageBase64,
    'status': status,
    'rejectReason': rejectReason,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Listing.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return Listing(
      id: id,
      sellerId: map['sellerId'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      brand: map['brand'] as String? ?? '',
      category: map['category'] as String? ?? 'Men',
      sizes: (map['sizes'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((size) => size.toInt())
          .toList(),
      imageBase64: map['imageBase64'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      rejectReason: map['rejectReason'] as String?,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : createdAt is DateTime
          ? createdAt
          : DateTime.tryParse('$createdAt') ?? DateTime.now(),
    );
  }
}
