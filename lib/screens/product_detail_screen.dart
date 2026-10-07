import 'package:ctadmobl_project/models/cart_item.dart';
import 'package:ctadmobl_project/models/product.dart';
import 'package:ctadmobl_project/models/review.dart';
import 'package:ctadmobl_project/providers/cart_provider.dart';
import 'package:ctadmobl_project/providers/favorites_provider.dart';
import 'package:ctadmobl_project/providers/review_provider.dart';
import 'package:ctadmobl_project/widgets/review_tile.dart';
import 'package:ctadmobl_project/widgets/product_image.dart';
import 'package:ctadmobl_project/theme/app_theme.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required this.product, super.key});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int? _size;
  int _imageIndex = 0;
  int _reviewStreamKey = 0;

  Future<void> _addToCart() async {
    if (_size == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a shoe size first')));
      return;
    }
    try {
      await context.read<CartProvider>().add(
        CartItem(
          productId: widget.product.id,
          title: widget.product.title,
          price: widget.product.price,
          thumbnail: widget.product.isListing
              ? widget.product.imageBase64 ?? ''
              : widget.product.thumbnail,
          quantity: 1,
          size: _size!,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added to cart')));
    } catch (error) {
      debugPrint('Unable to add product to cart: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(appErrorMessage),
          action: SnackBarAction(label: 'Retry', onPressed: _addToCart),
        ),
      );
    }
  }

  Future<void> _writeReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to write a review.')),
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final comment = TextEditingController();
    var rating = 5.0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write a Review',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: () =>
                          setSheetState(() => rating = index + 1.0),
                      icon: Icon(
                        index < rating.floor() ? Icons.star : Icons.star_border,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: comment,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Your review',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().length < 3
                      ? 'Write at least 3 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await context.read<ReviewProvider>().submit(
                          productId: widget.product.id,
                          userId: user.uid,
                          userName: user.displayName ?? 'Customer',
                          rating: rating,
                          comment: comment.text,
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      } catch (error) {
                        debugPrint('Unable to submit review: $error');
                        if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: const Text(appErrorMessage),
                            action: SnackBarAction(
                              label: 'Retry',
                              onPressed: _writeReview,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    comment.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final colors = Theme.of(context).colorScheme;
    final images = product.images.isEmpty
        ? [product.thumbnail]
        : product.images;
    final favorites = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoe details'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await favorites.toggle(product.id);
              } catch (error) {
                debugPrint('Unable to save favorite: $error');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(appErrorMessage),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () => favorites.toggle(product.id),
                    ),
                  ),
                );
              }
            },
            icon: Icon(
              favorites.contains(product.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: favorites.contains(product.id) ? colors.error : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: AppTheme.productImageBackground,
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _imageIndex = index),
                  itemBuilder: (context, index) => ProductImage(
                    value: images[index],
                    base64Image: product.imageBase64,
                    fit: BoxFit.contain,
                    iconSize: 56,
                  ),
                ),
              ),
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${_imageIndex + 1} / ${images.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(product.brand, style: Theme.of(context).textTheme.bodySmall),
          if (product.sellerName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Sold by ${product.sellerName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(product.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('\$${product.price.toStringAsFixed(2)}'),
          const SizedBox(height: 24),
          Text(
            'Select size (EU)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children:
                (product.availableSizes.isEmpty
                        ? List.generate(8, (index) => index + 38)
                        : product.availableSizes)
                    .map((size) {
                      return ChoiceChip(
                        label: Text('$size'),
                        selected: _size == size,
                        selectedColor: colors.primary,
                        labelStyle: TextStyle(
                          color: _size == size
                              ? colors.onPrimary
                              : colors.onSurface,
                        ),
                        onSelected: (_) => setState(() => _size = size),
                      );
                    })
                    .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addToCart,
              child: const Text('Add to Cart'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(product.description),
          const SizedBox(height: 24),
          StreamBuilder<List<Review>>(
            key: ValueKey(_reviewStreamKey),
            stream: context.read<ReviewProvider>().watchReviews(product.id),
            builder: (context, snapshot) {
              final userReviews = snapshot.data ?? const <Review>[];
              final reviews = [...product.reviews, ...userReviews];
              final average = reviews.isEmpty
                  ? product.rating
                  : reviews.fold<double>(
                          0,
                          (sum, review) => sum + review.rating,
                        ) /
                        reviews.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Reviews',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${average.toStringAsFixed(1)} ★  (${reviews.length})',
                      ),
                    ],
                  ),
                  if (snapshot.hasError)
                    Builder(
                      builder: (context) {
                        debugPrint(
                          'Unable to load customer reviews: ${snapshot.error}',
                        );
                        return SizedBox(
                          height: 140,
                          child: AppErrorState(
                            onRetry: () => setState(() => _reviewStreamKey++),
                          ),
                        );
                      },
                    )
                  else if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      product.reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No reviews yet.'),
                    )
                  else
                    ...reviews.map((review) => ReviewTile(review: review)),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _writeReview,
                      child: const Text('Write a Review'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
