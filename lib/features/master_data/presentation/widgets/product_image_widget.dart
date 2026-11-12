import 'dart:io';

import 'package:flutter/material.dart';

/// Displays a persistent local product image with safe fallback placeholder.
class ProductImageWidget extends StatelessWidget {
  const ProductImageWidget({
    super.key,
    required this.imagePath,
    this.width = 56,
    this.height = 56,
    this.borderRadius = 10,
    this.iconSize = 26,
  });

  final String? imagePath;
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasValidFile =
        path != null && path.isNotEmpty && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F5F9),
        child: hasValidFile
            ? Image.file(
                File(path),
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.fastfood_rounded,
        size: iconSize,
        color: Colors.grey.shade400,
      ),
    );
  }
}
