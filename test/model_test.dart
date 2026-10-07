import 'package:ctadmobl_project/models/cart_item.dart';
import 'package:ctadmobl_project/models/listing.dart';
import 'package:ctadmobl_project/models/product.dart';
import 'package:ctadmobl_project/models/review.dart';
import 'package:ctadmobl_project/providers/product_provider.dart';
import 'package:ctadmobl_project/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cart item map preserves selected size and quantity', () {
    const original = CartItem(
      productId: 'shoe-1',
      title: 'Runner',
      price: 79.5,
      thumbnail: 'https://example.com/shoe.jpg',
      quantity: 2,
      size: 42,
    );

    final decoded = CartItem.fromMap(original.toMap());
    expect(decoded.size, 42);
    expect(decoded.quantity, 2);
    expect(decoded.copyWith(size: 43).size, 43);
  });

  test('product parser reads source reviews', () {
    final product = Product.fromJson({
      'id': 7,
      'title': 'Runner',
      'price': 99,
      'rating': 4.5,
      'images': ['image.jpg'],
      'reviews': [
        {
          'reviewerName': 'Sam',
          'rating': 5,
          'comment': 'Great fit',
          'date': '2025-04-03T10:00:00.000Z',
        },
      ],
    });

    expect(product.id, '7');
    expect(product.reviews.single.reviewerName, 'Sam');
    expect(product.reviews.single.comment, 'Great fit');
  });

  test('review can round-trip through Firestore map', () {
    final review = Review(
      reviewerName: 'Alex',
      rating: 4,
      comment: 'Comfortable',
      date: DateTime.utc(2025, 3, 1),
      userId: 'user-1',
    );

    final decoded = Review.fromMap(review.toMap());
    expect(decoded.reviewerName, 'Alex');
    expect(decoded.rating, 4);
    expect(
      decoded.date.millisecondsSinceEpoch,
      review.date.millisecondsSinceEpoch,
    );
    expect(decoded.userId, 'user-1');
  });

  test('product provider filters and sorts fetched products', () async {
    final provider = ProductProvider(
      _FakeProductService([
        _product(id: '1', price: 30, rating: 3, category: 'mens-shoes'),
        _product(id: '2', price: 10, rating: 5, category: 'womens-shoes'),
        _product(id: '3', price: 20, rating: 4, category: 'mens-shoes'),
      ]),
    );
    await provider.loadProducts();

    provider.setSort(ProductSort.priceLowToHigh);
    expect(provider.products.map((product) => product.id), ['2', '3', '1']);

    provider.setCategory(ProductCategory.men);
    expect(provider.products.map((product) => product.id), ['3', '1']);

    provider.setSort(ProductSort.topRated);
    expect(provider.products.map((product) => product.id), ['3', '1']);
    provider.dispose();
  });

  test('listing round-trips and becomes a community product', () {
    final listing = Listing(
      id: 'listing-1',
      sellerId: 'seller-1',
      sellerName: 'Taylor',
      title: 'Leather runner',
      description: 'Gently worn',
      price: 45,
      brand: 'Local',
      category: 'Women',
      sizes: [38, 40],
      imageBase64: 'aW1hZ2U=',
      status: 'approved',
      rejectReason: null,
      createdAt: DateTime.utc(2025, 1, 1),
    );
    final decoded = Listing.fromMap(listing.id, listing.toMap());
    final product = Product.fromListing(decoded);

    expect(decoded.sizes, [38, 40]);
    expect(product.id, 'listing:listing-1');
    expect(product.availableSizes, [38, 40]);
    expect(product.sellerName, 'Taylor');
    expect(product.imageBase64, 'aW1hZ2U=');
    expect(product.isListing, isTrue);
  });
}

Product _product({
  required String id,
  required double price,
  required double rating,
  required String category,
}) {
  return Product(
    id: id,
    title: 'Shoe $id',
    description: '',
    price: price,
    rating: rating,
    brand: 'Brand',
    thumbnail: '',
    images: const [],
    category: category,
  );
}

class _FakeProductService extends ProductService {
  _FakeProductService(this.products);

  final List<Product> products;

  @override
  Future<List<Product>> fetchProducts() async => products;
}
