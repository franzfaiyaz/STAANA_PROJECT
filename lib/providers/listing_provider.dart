import 'package:ctadmobl_project/models/listing.dart';
import 'package:ctadmobl_project/services/listing_service.dart';
import 'package:flutter/foundation.dart';

class ListingProvider extends ChangeNotifier {
  ListingProvider(this._service);

  final ListingService _service;
  bool _isSubmitting = false;
  Object? _error;
  Object? get error => _error;
  bool get isSubmitting => _isSubmitting;

  Stream<List<Listing>> watchApprovedListings() =>
      _service.watchApprovedListings();

  Stream<List<Listing>> watchMyListings(String userId) =>
      _service.watchMyListings(userId);

  Stream<List<Listing>> watchPendingListings() =>
      _service.watchPendingListings();

  Future<void> createListing(Listing listing) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createListing(listing);
    } catch (error) {
      debugPrint('Unable to create listing: $error');
      _error = error;
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> approveListing(String id) async {
    try {
      await _service.approveListing(id);
      _error = null;
    } catch (error) {
      debugPrint('Unable to approve listing: $error');
      _error = error;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> rejectListing(String id, String reason) async {
    try {
      await _service.rejectListing(id, reason);
      _error = null;
    } catch (error) {
      debugPrint('Unable to reject listing: $error');
      _error = error;
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
