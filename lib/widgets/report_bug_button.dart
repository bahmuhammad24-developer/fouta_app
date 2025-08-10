import 'package:flutter/material.dart';

import '../screens/report_bug_screen.dart';

/// Whether to show the floating debug bug button in non-release builds.
const bool kShowBugFabInDebug = true;

/// Wraps [child] with a tap handler that opens [ReportBugScreen].
class ReportBugButton extends StatelessWidget {
  const ReportBugButton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportBugScreen()),
        );
      },
      child: child,
    );
  }
}

