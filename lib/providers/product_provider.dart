import 'package:ctadmobl_project/models/product.dart';
import 'package:ctadmobl_project/services/product_service.dart';
import 'package:flutter/foundation.dart';

enum ProductCategory { all, men, women }

enum ProductSort { recommended, priceLowToHigh, priceHighToLow, topRated }

class ProductProvider extends ChangeNotifier {
  ProductProvider(this._service) {
    loadProducts();
  }

  final ProductService _service;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  ProductCategory _category = ProductCategory.all;
  ProductSort _sort = ProductSort.recommended;

  List<Product> get products {
    final categoryKey = switch (_category) {
      ProductCategory.all => null,
      ProductCategory.men => 'mens-shoes',
      ProductCategory.women => 'womens-shoes',
    };
    final result = _products.where((product) {
      final matchesCategory =
          categoryKey == null || product.category == categoryKey;
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    switch (_sort) {
      case ProductSort.recommended:
        break;
      case ProductSort.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
      case ProductSort.topRated:
        result.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return result;
  }

  List<Product> get allProducts => List.unmodifiable(_products);
  List<Product> filterAndSort(List<Product> source) {
    final categoryKey = switch (_category) {
      ProductCategory.all => null,
      ProductCategory.men => 'men',
      ProductCategory.women => 'women',
    };
    final query = _searchQuery.toLowerCase();
    final filtered = source.where((product) {
      final category = product.category.toLowerCase();
      final matchesCategory =
          categoryKey == null ||
          category == categoryKey ||
          category.startsWith('${categoryKey}s-');
      final matchesQuery =
          query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
    switch (_sort) {
      case ProductSort.recommended:
        break;
      case ProductSort.priceLowToHigh:
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceHighToLow:
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case ProductSort.topRated:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return filtered;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  ProductCategory get category => _category;
  ProductSort get sort => _sort;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _service.fetchProducts();
    } catch (error) {
      debugPrint('Unable to load products: $error');
      _error = 'Something went wrong. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    notifyListeners();
  }

  void setCategory(ProductCategory value) {
    _category = value;
    notifyListeners();
  }

  void setSort(ProductSort value) {
    _sort = value;
    notifyListeners();
  }
}
