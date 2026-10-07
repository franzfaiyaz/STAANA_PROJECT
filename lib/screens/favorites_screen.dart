import 'package:ctadmobl_project/models/listing.dart';
import 'package:ctadmobl_project/models/product.dart';
import 'package:ctadmobl_project/providers/favorites_provider.dart';
import 'package:ctadmobl_project/providers/listing_provider.dart';
import 'package:ctadmobl_project/providers/product_provider.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:ctadmobl_project/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _streamKey = 0;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final productsProvider = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isLoading || productsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.error != null || productsProvider.error != null
          ? AppErrorState(
              onRetry: () {
                favorites.reload();
                productsProvider.loadProducts();
                setState(() => _streamKey++);
              },
            )
          : StreamBuilder<List<Listing>>(
              key: ValueKey(_streamKey),
              stream: context.read<ListingProvider>().watchApprovedListings(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    'Unable to load listings for favorites: ${snapshot.error}',
                  );
                  return AppErrorState(
                    onRetry: () => setState(() => _streamKey++),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildFavorites(
                  context,
                  favorites,
                  productsProvider,
                  snapshot.data!,
                );
              },
            ),
    );
  }

  Widget _buildFavorites(
    BuildContext context,
    FavoritesProvider favorites,
    ProductProvider productsProvider,
    List<Listing> listings,
  ) {
    final products = <Product>[
      ...productsProvider.allProducts,
      ...listings.map(Product.fromListing),
    ].where((product) => favorites.contains(product.id)).toList();
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 40,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              const Text('You have no saved shoes yet.'),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 18,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) => ProductCard(product: products[index]),
    );
  }
}
