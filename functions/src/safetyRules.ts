const FORBIDDEN_WORDS = ['forbidden'];

export function checkSafetyRules(data: {text?: string; mediaUrl?: string}): string[] {
  const violations: string[] = [];
  if (data.mediaUrl) {
    try {
      const url = new URL(data.mediaUrl);
      if (url.protocol !== 'http:' && url.protocol !== 'https:') {
        violations.push('invalid-media-url');
      }
    } catch {
      violations.push('invalid-media-url');
    }
  }
  if (data.text) {
    if (data.text.length > 280) {
      violations.push('text-too-long');
    }
    const lower = data.text.toLowerCase();
    if (FORBIDDEN_WORDS.some(w => lower.includes(w))) {
      violations.push('forbidden-word');
    }
  }
  return violations;
}
