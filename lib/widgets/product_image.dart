import 'dart:convert';

import 'package:ctadmobl_project/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.value,
    this.base64Image,
    this.fit = BoxFit.cover,
    this.iconSize = 40,
    super.key,
  });

  final String value;
  final String? base64Image;
  final BoxFit fit;
  final double iconSize;

  bool get _isDataUrl => value.startsWith('data:image/');

  @override
  Widget build(BuildContext context) {
    final imageData =
        base64Image ??
        (_isDataUrl
            ? value.split(',').last
            : value.startsWith('http')
            ? null
            : value);
    if (imageData != null && imageData.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(imageData),
          fit: fit,
          errorBuilder: (_, _, _) => _error(context),
        );
      } on FormatException {
        return _error(context);
      }
    }
    if (value.isEmpty) return _error(context);

    return Image.network(
      value,
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, _, _) => _error(context),
    );
  }

  Widget _error(BuildContext context) => ColoredBox(
    color: AppTheme.productImageBackground,
    child: Center(
      child: Icon(
        Icons.directions_run_outlined,
        size: iconSize,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ),
  );
}
