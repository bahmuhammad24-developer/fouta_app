import 'package:flutter/material.dart';

Future<T?> showFoutaDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

Future<T?> showFoutaBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: builder,
  );
}
