
export interface SafetyResult {
  ok: boolean;
  reason?: string;
}

const FORBIDDEN_WORDS = ['spam', 'scam', 'fake'];

export function checkSafetyRules(data: any): SafetyResult {
  const content = (data?.content || '').trim();
  if (!content) {
    return { ok: false, reason: 'empty-content' };
  }
  if (content.length > 5000) {
    return { ok: false, reason: 'too-long' };
  }
  const lower = content.toLowerCase();
  if (FORBIDDEN_WORDS.some((w) => lower.includes(w))) {
    return { ok: false, reason: 'forbidden-content' };
  }
  const media = data?.media;
  if (Array.isArray(media)) {
    for (const url of media) {
      if (typeof url !== 'string' || !url.startsWith('https://')) {
        return { ok: false, reason: 'insecure-media-url' };
      }
    }
  }
  return { ok: true };

}
