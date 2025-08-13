import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/link_preview/link_preview_service.dart';

void main() {
  group('LinkPreviewService.normalizeUrl', () {
    test('adds https scheme when missing', () {
      expect(
        LinkPreviewService.normalizeUrl('example.com'),
        'https://example.com',
      );
    });

    test('trims whitespace', () {
      expect(
        LinkPreviewService.normalizeUrl(' https://foo.com '),
        'https://foo.com',
      );
    });

    test('rejects non-http schemes', () {
      expect(LinkPreviewService.normalizeUrl('ftp://foo.com'), isNull);
    });
  });
}
