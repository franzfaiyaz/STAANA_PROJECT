import 'package:ctadmobl_project/models/listing.dart';
import 'package:ctadmobl_project/models/review.dart';

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.brand,
    required this.thumbnail,
    required this.images,
    required this.category,
    this.reviews = const [],
    this.imageBase64,
    this.sellerName,
    this.sellerId,
    this.listingId,
    this.availableSizes = const [],
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final String brand;
  final String thumbnail;
  final List<String> images;
  final String category;
  final List<Review> reviews;
  final String? imageBase64;
  final String? sellerName;
  final String? sellerId;
  final String? listingId;
  final List<int> availableSizes;

  bool get isListing => listingId != null;

  factory Product.fromListing(Listing listing) {
    return Product(
      id: 'listing:${listing.id}',
      title: listing.title,
      description: listing.description,
      price: listing.price,
      rating: 0,
      brand: listing.brand,
      thumbnail: '',
      images: const [],
      category: listing.category.toLowerCase(),
      imageBase64: listing.imageBase64,
      sellerName: listing.sellerName,
      sellerId: listing.sellerId,
      listingId: listing.id,
      availableSizes: listing.sizes,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: '${json['id']}',
      title: json['title'] as String? ?? 'Untitled shoe',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      brand: json['brand'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      category: json['category'] as String? ?? '',
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Review.fromJson)
          .toList(),
    );
  }
}
