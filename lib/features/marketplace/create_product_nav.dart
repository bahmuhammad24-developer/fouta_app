import 'package:flutter/material.dart';
import 'create_product_screen.dart';

Future<void> navigateToCreateProduct(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CreateProductScreen()),
  );
}
