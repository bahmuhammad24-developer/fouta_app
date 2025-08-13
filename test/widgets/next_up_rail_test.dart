import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/triggers/next_up_rail.dart';
import 'package:fouta_app/features/discovery/discovery_service.dart';

class _FakeDiscoveryService extends DiscoveryService {
  @override
  List<String> recommendedPosts() => ['one', 'two', 'three'];
}

void main() {
  testWidgets('NextUpRail renders 3 items', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: NextUpRail(
        service: _FakeDiscoveryService(),
        onSelected: (_) {},
      ),
    ));
    expect(find.byType(Card), findsNWidgets(3));
  });
}
