import 'package:ctadmobl_project/models/listing.dart';
import 'package:ctadmobl_project/providers/auth_provider.dart';
import 'package:ctadmobl_project/providers/listing_provider.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:ctadmobl_project/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _streamKey = 0;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(child: Text('Admin access required.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: StreamBuilder<List<Listing>>(
        key: ValueKey(_streamKey),
        stream: context.read<ListingProvider>().watchPendingListings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Unable to load pending listings: ${snapshot.error}');
            return AppErrorState(
              onRetry: () => setState(() => _streamKey++),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final listings = snapshot.data!;
          if (listings.isEmpty) {
            return const Center(child: Text('No listings waiting.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: listings.length,
            separatorBuilder: (_, _) => const Divider(height: 32),
            itemBuilder: (context, index) =>
                _PendingListingCard(listing: listings[index]),
          );
        },
      ),
    );
  }
}

class _PendingListingCard extends StatelessWidget {
  const _PendingListingCard({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ListingProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 190,
            child: ProductImage(
              value: '',
              base64Image: listing.imageBase64,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('\$${listing.price.toStringAsFixed(2)} · ${listing.brand}'),
        Text('Seller: ${listing.sellerName}'),
        const SizedBox(height: 8),
        Text(listing.description),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _reject(context, provider),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await provider.approveListing(listing.id);
                  } catch (error) {
                    debugPrint('Unable to approve listing: $error');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(appErrorMessage),
                        action: SnackBarAction(
                          label: 'Retry',
                          onPressed: () => provider.approveListing(listing.id),
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Approve'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _reject(BuildContext context, ListingProvider provider) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject listing'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Reason'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a reason' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(reasonController.text.trim());
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !context.mounted) return;
    try {
      await provider.rejectListing(listing.id, reason);
    } catch (error) {
      debugPrint('Unable to reject listing: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(appErrorMessage),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => provider.rejectListing(listing.id, reason),
          ),
        ),
      );
    }
  }
}
