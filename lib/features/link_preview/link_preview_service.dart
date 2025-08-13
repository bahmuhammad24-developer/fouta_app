import 'package:http/http.dart' as http;

/// Data returned by [LinkPreviewService].
class LinkPreviewData {
  const LinkPreviewData({
    required this.title,
    this.description,
    this.imageUrl,
    this.siteName,
  });

  final String title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
}

/// Service for fetching Open Graph data for a URL.
class LinkPreviewService {
  const LinkPreviewService();

  /// Normalizes [url] and ensures it uses http/https.
  static String? normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    Uri? uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme.isEmpty) {
      uri = Uri.parse('https://$trimmed');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri.toString();
  }

  /// Fetches Open Graph metadata for [url].
  /// Returns null if the URL is invalid or data cannot be fetched.
  Future<LinkPreviewData?> fetch(String url) async {
    final normalized = normalizeUrl(url);
    if (normalized == null) return null;
    try {
      final resp = await http.get(Uri.parse(normalized));
      if (resp.statusCode != 200) return null;
      final html = resp.body;
      String? _meta(String property) {
        final exp = RegExp(
          '<meta[^>]+property=["\']$property["\'][^>]*content=["\']([^"\']+)["\']',
          caseSensitive: false,
        );
        return exp.firstMatch(html)?.group(1);
      }

      String? title = _meta('og:title') ?? _titleFromHtml(html);
      if (title == null) return null;
      return LinkPreviewData(
        title: title,
        description: _meta('og:description'),
        imageUrl: _meta('og:image'),
        siteName: _meta('og:site_name') ?? Uri.parse(normalized).host,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _titleFromHtml(String html) {
    final exp = RegExp('<title>([^<]*)</title>', caseSensitive: false);
    return exp.firstMatch(html)?.group(1);
  }
}

