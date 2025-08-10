# AI Guardrails (Fouta)
- Do not change bottom nav order/labels: Feed, Chat, Events, People, Profile.
- Follow system appearance; do not force dark or light by default.
- Use Material 3; use ColorScheme roles ONLY (no hard-coded Colors.*).
- Keep component surfaceTintColor transparent unless specifically needed.
- Gradients are limited to: selected nav icon glow; story ring; subtle photo overlays.
- Stories: tap = photo; long-press = video (≤15s); pass captured media to composer.
- Story rings: unviewed primary→secondary gradient; viewed grey.
- Theme switching: Auto/Light/Dark via ThemeController; avoid forcing brightness.
- Any new component must use tokens in /brand/tokens.json; if a color/token is missing, add it there first.
- Check AA contrast for text; run scripts/validate.sh before PR.

