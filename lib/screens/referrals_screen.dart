import 'package:flutter/material.dart';
import 'package:fouta_app/features/growth/growth_service.dart';
import 'package:share_plus/share_plus.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  late final GrowthService _growth = GrowthService();
  late final String _code = _growth.createReferralCode(widget.userId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Friends')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your code: $_code'),
            const SizedBox(height: 16),
            Semantics(
              label: 'Share referral code',
              button: true,
              child: ElevatedButton(
                onPressed: () {
                  Share.share('Join me on Fouta. Code: $_code');
                },
                child: const Text('Share'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
