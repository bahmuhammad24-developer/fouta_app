export function checkSafetyRules(data: any): { ok: boolean; reason?: string } {
  const text = (data?.content ?? '').toString().trim();
  if (!text) return { ok: false, reason: 'empty_content' };
  if (text.length > 5000) return { ok: false, reason: 'content_too_long' };
  const forbidden = ['hateword1', 'slur1']; // placeholder list
  const lower = text.toLowerCase();
  if (forbidden.some(w => lower.includes(w))) {
    return { ok: false, reason: 'forbidden_terms' };
  }
  const media = data?.media;
  const urls: string[] = Array.isArray(media) ? media : (media?.urls ?? []);
  if (urls.some(u => !/^https:\/\//i.test(String(u)))) {
    return { ok: false, reason: 'insecure_media_url' };
  }
  return { ok: true };
}
