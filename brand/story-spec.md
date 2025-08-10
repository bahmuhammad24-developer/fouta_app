# Story Feature (v1)
- Entry: Stories row → “Your Story” (plus ring).
- Capture: tap=photo, long-press=video up to 15s, progress ring visible.
- Composer: preview → optional text overlay → Share to Story (not a post).
- Publish:
  - Storage: /stories/{userId}/{uuid}.(jpg|mp4)
  - Firestore:
    /artifacts/{appId}/public/data/stories/{userId} (userId, updatedAt)
    /slides/{slideId}: {type, url, thumbUrl?, durationMs, createdAt, expiresAt}
  - Durations: image=6000ms; video=min(videoLength,15000ms)
  - Expiry: 24h (client hides expired; server cleanup can be added later)
- Viewer: tap right/left, press-hold pause, swipe down to dismiss, auto-advance.
- Rings: unviewed=primary→secondary gradient; viewed=grey.
- Accessibility: captions/overlay text must meet AA contrast; tap targets ≥48dp.
