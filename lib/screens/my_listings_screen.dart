import 'package:ctadmobl_project/models/listing.dart';
import 'package:ctadmobl_project/providers/listing_provider.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:ctadmobl_project/widgets/product_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  int _streamKey = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      body: uid == null
          ? const Center(child: Text('Sign in to view your listings.'))
          : StreamBuilder<List<Listing>>(
              key: ValueKey(_streamKey),
              stream: context.read<ListingProvider>().watchMyListings(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Unable to load listings: ${snapshot.error}');
                  return AppErrorState(
                    onRetry: () => setState(() => _streamKey++),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final listings = snapshot.data!;
                if (listings.isEmpty) {
                  return const Center(child: Text('You have no listings yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: listings.length,
                  separatorBuilder: (_, _) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _ListingTile(listing: listing);
                  },
                );
              },
            ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = switch (listing.status) {
      'approved' => colors.primary,
      'rejected' => colors.error,
      _ => colors.secondary,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 76,
            height: 76,
            child: ProductImage(value: '', base64Image: listing.imageBase64),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('\$${listing.price.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              Text(switch (listing.status) {
                'approved' => 'Approved',
                'rejected' => 'Rejected',
                _ => 'Pending',
              }, style: TextStyle(color: statusColor)),
              if (listing.status == 'rejected' &&
                  listing.rejectReason?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  listing.rejectReason!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
