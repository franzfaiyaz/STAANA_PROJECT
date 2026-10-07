import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctadmobl_project/models/listing.dart';

class ListingService {
  ListingService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('listings');

  Stream<List<Listing>> watchApprovedListings() {
    return _listings
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(_parse);
  }

  Stream<List<Listing>> watchMyListings(String sellerId) {
    return _listings
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(_parse);
  }

  Stream<List<Listing>> watchPendingListings() {
    return _listings
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(_parse);
  }

  Future<void> createListing(Listing listing) async {
    await _listings.doc(listing.id).set(listing.toMap());
  }

  Future<void> approveListing(String listingId) {
    return _listings.doc(listingId).update({
      'status': 'approved',
      'rejectReason': FieldValue.delete(),
    });
  }

  Future<void> rejectListing(String listingId, String reason) {
    return _listings.doc(listingId).update({
      'status': 'rejected',
      'rejectReason': reason.trim(),
    });
  }

  List<Listing> _parse(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final listings = snapshot.docs
        .map((doc) => Listing.fromMap(doc.id, doc.data()))
        .toList();
    listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return listings;
  }
}
