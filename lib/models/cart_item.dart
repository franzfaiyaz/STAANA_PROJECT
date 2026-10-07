class CartItem {
  const CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.quantity,
    required this.size,
  });

  final String productId;
  final String title;
  final double price;
  final String thumbnail;
  final int quantity;
  final int size;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'title': title,
    'price': price,
    'thumbnail': thumbnail,
    'quantity': quantity,
    'size': size,
  };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    productId: map['productId'] as String,
    title: map['title'] as String,
    price: (map['price'] as num).toDouble(),
    thumbnail: map['thumbnail'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    size: (map['size'] as num).toInt(),
  );

  CartItem copyWith({int? quantity, int? size}) => CartItem(
    productId: productId,
    title: title,
    price: price,
    thumbnail: thumbnail,
    quantity: quantity ?? this.quantity,
    size: size ?? this.size,
  );
}
