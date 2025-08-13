import * as functions from 'firebase-functions';

export const openGraph = functions.https.onRequest(async (req, res) => {
  const url = (req.query.url as string | undefined)?.toString().trim() ?? '';
  if (!/^https?:\/\//i.test(url)) {
    res.status(400).json({ error: 'invalid-url' });
    return;
  }
  try {
    const response = await fetch(url);
    const html = await response.text();
    const meta = (property: string): string | null => {
      const regex = new RegExp(
        `<meta[^>]+property=['\"]${property}['\"][^>]*content=['\"]([^'\"]+)['\"]`,
        'i',
      );
      return regex.exec(html)?.[1] ?? null;
    };
    res.json({
      title: meta('og:title'),
      description: meta('og:description'),
      imageUrl: meta('og:image'),
      siteName: meta('og:site_name'),
    });
  } catch (e) {
    res.status(500).json({ error: 'fetch-failed' });
  }
});

