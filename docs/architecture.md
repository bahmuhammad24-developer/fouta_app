# Architecture & Competitive Alignment

Fouta's architecture is expanding to match capabilities of major social platforms while centering the global majority.

## Feature Modules

| Module | Purpose | Competitive targets |
|--------|---------|--------------------|
| Discovery | Hashtags, search, and personalized feed ranking | Facebook's News Feed, X trends |
| Moderation | Reporting, blocking, and community review | Instagram safety tools |
| Growth | Onboarding, referrals, and social graph import | Facebook friend finder, TikTok invites |
| Creation tools | AR filters, captioning, lightweight editing | Snapchat lenses, TikTok editor |
| Analytics | Usage metrics and performance tracing | Platform analytics dashboards |
| Monetization | Ads, subscriptions, and marketplace support | Instagram shopping, TikTok coins |

Each module lives under `lib/features` as a scaffolded service with room for future implementation.

## Next Steps

1. Flesh out service implementations and connect them to Firebase and Cloud Functions.
2. Experiment with feed ranking algorithms and hashtag parsing.
3. Build reporting queues and automated moderation rules.
4. Design referral flows and contact syncing to boost early growth.
5. Instrument analytics events across screens and widgets.
6. Validate monetization strategies with small pilots before scaling.
