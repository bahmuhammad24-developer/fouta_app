import 'package:flutter/material.dart';
import 'package:fouta_app/screens/report_bug_screen.dart';

class ReportBugButton extends StatelessWidget {
  const ReportBugButton({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportBugScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bug_report_outlined, color: cs.onSurface, size: 20),
            const SizedBox(width: 8),
            Text('Report a Bug', style: TextStyle(color: cs.onSurface)),
          ]),
        ),
      ),
    );
  }
}
