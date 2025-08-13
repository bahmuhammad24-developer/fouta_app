// lib/navigation/dev_routes.dart
import 'package:flutter/widgets.dart';
import 'nav_v2_scaffold.dart';

Map<String, WidgetBuilder> devRoutes() => {
      NavV2Scaffold.route: (_) => const NavV2Scaffold(),
    };
