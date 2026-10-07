import 'dart:convert';

import 'package:ctadmobl_project/models/product.dart';
import 'package:http/http.dart' as http;

class ProductService {
  static const _categories = ['mens-shoes', 'womens-shoes'];

  Future<List<Product>> fetchProducts() async {
    final products = <Product>[];
    for (final category in _categories) {
      final response = await http.get(
        Uri.https('dummyjson.com', '/products/category/$category'),
      );
      if (response.statusCode != 200) {
        throw Exception('Could not load shoes (${response.statusCode}).');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final entries = decoded['products'] as List<dynamic>? ?? const [];
      products.addAll(
        entries.whereType<Map<String, dynamic>>().map(
          (json) => Product.fromJson({...json, 'category': category}),
        ),
      );
    }
    return products;
  }
}
