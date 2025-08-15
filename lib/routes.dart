// lib/routes.dart

import 'package:flutter/widgets.dart';
import 'features/challenges/challenges_feed_screen.dart';

/// Global route table for the application.
Map<String, WidgetBuilder> appRoutes() => {
      ChallengesFeedScreen.route: (_) => const ChallengesFeedScreen(),
    };
