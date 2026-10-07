import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctadmobl_project/models/review.dart';
import 'package:flutter/foundation.dart';

class ReviewProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Review>> watchReviews(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Review.fromMap(doc.data())).toList(),
        );
  }

  Future<void> submit({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    final review = Review(
      reviewerName: userName,
      rating: rating,
      comment: comment.trim(),
      date: DateTime.now(),
      userId: userId,
    );
    final ref = _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        throw StateError('You have already reviewed this shoe.');
      }
      transaction.set(ref, review.toMap());
    });
  }
}
