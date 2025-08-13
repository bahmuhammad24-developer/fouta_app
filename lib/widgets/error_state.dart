import 'package:flutter/material.dart';

/// Basic error UI used by safe builders.
class ErrorState extends StatelessWidget {
  final String message;

  const ErrorState({super.key, this.message = 'Something went wrong.'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
