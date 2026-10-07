import 'package:ctadmobl_project/models/product.dart';
import 'package:ctadmobl_project/providers/favorites_provider.dart';
import 'package:ctadmobl_project/screens/product_detail_screen.dart';
import 'package:ctadmobl_project/theme/app_theme.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:ctadmobl_project/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final favorites = context.watch<FavoritesProvider>();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: AppTheme.productImageBackground,
                    child: ProductImage(
                      value: product.thumbnail,
                      base64Image: product.imageBase64,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
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
                    color: favorites.contains(product.id)
                        ? colors.error
                        : colors.onSurface,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surface.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
