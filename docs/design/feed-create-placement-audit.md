# Feed & Create Placement Audit

## Feed Screens
- Original feed cards mixed ad-hoc buttons and inconsistent action ordering.
- Applied FoutaButton for follow/unfollow prompts and standardized like, comment, share, bookmark actions.
- Added semantic labels and tooltips for all icon actions to improve accessibility.

## Create Flows
- Previously used elevated/text buttons and floating action buttons.
- Replaced with tiered FoutaButton components: primary full-width submit at bottom, secondary cancel and clear actions.
- Media pickers consolidated as icon buttons with consistent spacing.
- Story composer now uses bottom-aligned FoutaButtons instead of a floating action button.

## Rationale
These adjustments align with the design system tiers:
- **Tier 2:** core buttons (`FoutaButton`, styled `IconButton`).
- **Tier 3:** composite placements (feed card actions, create flow footers).

## Use Case Flow Support
1. **Discover feed:** Consistent actions and reachable CTAs encourage browsing and engagement.
2. **Create post/story:** Full-width submit buttons at thumb-friendly bottom locations streamline publishing.
3. **Engage:** Standardized like/comment/share positions make interactions predictable and accessible.

Documented decisions aim to keep future iterations consistent with ergonomic and system guidelines.
