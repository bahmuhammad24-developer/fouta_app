# Tiered Design System Structure

## Tier 1 – Foundation
Design tokens define the visual primitives for color, typography, spacing, radius, elevation, and motion. They live in [`lib/theme/tokens.dart`](../../lib/theme/tokens.dart).

## Tier 2 – Core Components
Reusable widgets styled with Tier 1 tokens. Examples include buttons, text fields, cards, skeleton loaders, and progressive images.

## Tier 3 – Feature Composites
Feature-specific pieces built from Tier 2 components, such as marketplace product cards, chat message bubbles, or a story tray.

## Tier 4 – Screen Templates
Complete screens composed of Tier 2 and Tier 3 elements. Examples: `MarketplaceScreen`, `ProfileScreen`, `Feed`, `CreatePost`.

## Benefits
- **Consistency** – shared tokens and components keep the UI cohesive.
- **Maintainability** – updates cascade through tiers with minimal churn.
- **Faster theming** – changing a token restyles dependent components.
- **Accessible by default** – components bake in a11y considerations.

## Usage Guidelines
- Start from the lowest tier that meets the requirement.
- Avoid skipping tiers; doing so introduces design drift and one-off styles.
