import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  const Review({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
    this.userId,
  });

  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime date;
  final String? userId;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    reviewerName:
        json['reviewerName'] as String? ??
        json['userName'] as String? ??
        'Customer',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    comment: json['comment'] as String? ?? '',
    date: _dateFrom(json['date'] ?? json['createdAt']),
    userId: json['userId'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': reviewerName,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(date),
  };

  factory Review.fromMap(Map<String, dynamic> map) => Review.fromJson(map);

  static DateTime _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
