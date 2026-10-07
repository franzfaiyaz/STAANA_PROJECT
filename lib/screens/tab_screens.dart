import 'package:ctadmobl_project/models/product.dart';
import 'package:ctadmobl_project/models/user_profile.dart';
import 'package:ctadmobl_project/models/listing.dart';
import 'package:ctadmobl_project/providers/cart_provider.dart';
import 'package:ctadmobl_project/providers/product_provider.dart';
import 'package:ctadmobl_project/providers/listing_provider.dart';
import 'package:ctadmobl_project/providers/auth_provider.dart';
import 'package:ctadmobl_project/screens/checkout_screen.dart';
import 'package:ctadmobl_project/screens/edit_profile_screen.dart';
import 'package:ctadmobl_project/screens/favorites_screen.dart';
import 'package:ctadmobl_project/screens/orders_screen.dart';
import 'package:ctadmobl_project/screens/product_detail_screen.dart';
import 'package:ctadmobl_project/screens/sell_shoe_screen.dart';
import 'package:ctadmobl_project/screens/my_listings_screen.dart';
import 'package:ctadmobl_project/screens/admin_screen.dart';
import 'package:ctadmobl_project/services/auth_service.dart';
import 'package:ctadmobl_project/theme/app_theme.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:ctadmobl_project/widgets/product_card.dart';
import 'package:ctadmobl_project/widgets/theme_mode_tile.dart';
import 'package:ctadmobl_project/widgets/product_image.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _listingStreamKey = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final colors = Theme.of(context).colorScheme;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return AppErrorState(onRetry: provider.loadProducts);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Text(
                'Community Picks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SellShoeScreen(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Sell'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 178,
          child: StreamBuilder<List<Listing>>(
            key: ValueKey(_listingStreamKey),
            stream: context.read<ListingProvider>().watchApprovedListings(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(
                  'Unable to load community listings: ${snapshot.error}',
                );
                return AppErrorState(
                  onRetry: () => setState(() => _listingStreamKey++),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final listings = snapshot.data!;
              if (listings.isEmpty) {
                return Center(
                  child: Text(
                    'No community listings yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return PageView.builder(
                controller: PageController(viewportFraction: 0.85),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final product = Product.fromListing(listings[index]);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColoredBox(
                          color: AppTheme.productImageBackground,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 150,
                                height: double.infinity,
                                child: ProductImage(
                                  value: '',
                                  base64Image: product.imageBase64,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        product.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Sold by ${product.sellerName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            onChanged: provider.setSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search shoes',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: ProductCategory.values.map((category) {
              final selected = provider.category == category;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(switch (category) {
                    ProductCategory.all => 'All',
                    ProductCategory.men => 'Men',
                    ProductCategory.women => 'Women',
                  }),
                  selected: selected,
                  onSelected: (_) => provider.setCategory(category),
                  selectedColor: colors.primary,
                  labelStyle: TextStyle(
                    color: selected ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Text('Shoes', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              DropdownButton<ProductSort>(
                value: provider.sort,
                underline: const SizedBox.shrink(),
                onChanged: (sort) {
                  if (sort != null) provider.setSort(sort);
                },
                items: const [
                  DropdownMenuItem(
                    value: ProductSort.recommended,
                    child: Text('Recommended'),
                  ),
                  DropdownMenuItem(
                    value: ProductSort.priceLowToHigh,
                    child: Text('Price: low to high'),
                  ),
                  DropdownMenuItem(
                    value: ProductSort.priceHighToLow,
                    child: Text('Price: high to low'),
                  ),
                  DropdownMenuItem(
                    value: ProductSort.topRated,
                    child: Text('Top rated'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Listing>>(
            key: ValueKey(_listingStreamKey),
            stream: context.read<ListingProvider>().watchApprovedListings(),
            builder: (context, snapshot) {
              final combined = [
                ...provider.allProducts,
                ...?snapshot.data?.map(Product.fromListing),
              ];
              final products = provider.filterAndSort(combined);
              if (snapshot.hasError && provider.allProducts.isEmpty) {
                debugPrint(
                  'Unable to load community listings: ${snapshot.error}',
                );
                return AppErrorState(
                  onRetry: () => setState(() => _listingStreamKey++),
                );
              }
              if (!snapshot.hasData && provider.allProducts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (products.isEmpty) {
                return const _MessageState(
                  icon: Icons.search_off,
                  message: 'No shoes match your search.',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) =>
                    ProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.isLoading) return const Center(child: CircularProgressIndicator());
    if (cart.error != null) {
      return AppErrorState(onRetry: cart.reload);
    }
    if (cart.items.isEmpty) {
      return const _MessageState(
        icon: Icons.shopping_bag_outlined,
        message: 'Your cart is empty for now.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return Row(
                children: [
                  _ShoeThumbnail(url: item.thumbnail),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title),
                        Text(
                          'EU ${item.size} · \$${item.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _runCartAction(
                                context,
                                () => cart.changeQuantity(item, -1),
                              ),
                              icon: const Icon(Icons.remove),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () => _runCartAction(
                                context,
                                () => cart.changeQuantity(item, 1),
                              ),
                              icon: const Icon(Icons.add),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _runCartAction(
                                context,
                                () => cart.remove(item),
                              ),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _CartSummary(total: cart.total),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _profileStreamKey = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _MessageState(
        icon: Icons.person_outline,
        message: 'Sign in to view your profile.',
      );
    }
    return StreamBuilder<UserProfile?>(
      key: ValueKey(_profileStreamKey),
      stream: context.read<AuthService>().watchProfile(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Unable to load profile: ${snapshot.error}');
          return AppErrorState(
            onRetry: () => setState(() => _profileStreamKey++),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = snapshot.data!;
        final name = profile.name.isEmpty ? 'Customer' : profile.name;
        final initials = name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Text(
                initials,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(profile.email),
            const SizedBox(height: 4),
            Text(profile.phone),
            const SizedBox(height: 4),
            Text(profile.address),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditProfileScreen(),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.favorite_border),
              title: const Text('Favorites'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FavoritesScreen(),
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Orders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
              ),
            ),
            const Divider(),
            const ThemeModeTile(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sell_outlined),
              title: const Text('Sell a shoe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SellShoeScreen()),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('My listings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyListingsScreen(),
                ),
              ),
            ),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isAdmin) return const SizedBox.shrink();
                return StreamBuilder<List<Listing>>(
                  stream: context
                      .read<ListingProvider>()
                      .watchPendingListings(),
                  builder: (context, snapshot) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: const Text('Admin Panel'),
                    trailing: Badge(
                      isLabelVisible: (snapshot.data?.length ?? 0) > 0,
                      label: Text('${snapshot.data?.length ?? 0}'),
                      child: const Icon(Icons.chevron_right),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminScreen(),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (error) {
                  debugPrint('Unable to log out: $error');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(appErrorMessage),
                      action: SnackBarAction(
                        label: 'Retry',
                        onPressed: () => FirebaseAuth.instance.signOut(),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Total'),
              const Spacer(),
              Text('\$${total.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()),
              ),
              child: const Text('Checkout'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShoeThumbnail extends StatelessWidget {
  const _ShoeThumbnail({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(width: 72, height: 72, child: ProductImage(value: url)),
  );
}

Future<void> _runCartAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    debugPrint('Unable to update cart: $error');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(appErrorMessage),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _runCartAction(context, action),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
