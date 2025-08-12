import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/discovery/discovery_service.dart';

void main() {
  test('indexPost tracks trending hashtags', () {
    final service = DiscoveryService();
    service.indexPost('hello #world');
    service.indexPost('another #world #foo');
    final trending = service.trendingTags(limit: 2);
    expect(trending.first, '#world');
    expect(trending, contains('#foo'));
    expect(service.search('another'), ['another #world #foo']);
  });

  test('recommendedPosts returns posts with top tag', () {
    final service = DiscoveryService();
    service.indexPost('one #tag');
    service.indexPost('two #tag');
    service.indexPost('three #other');
    final rec = service.recommendedPosts();
    expect(rec, containsAll(['one #tag', 'two #tag']));
  });
}
