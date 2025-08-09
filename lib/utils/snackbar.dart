import 'package:flutter/material.dart';

class AppSnackBar {
  AppSnackBar._();

  static void show(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  static void showBanner(BuildContext context, String message,
      {bool isError = false, List<Widget>? actions}) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        actions: actions ??
            [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).clearMaterialBanners(),
                child: const Text('Dismiss'),
              )
            ],
      ),
    );
  }
}
