# Tiered Design System

## Philosophy
The tiered system provides a consistent visual hierarchy:
- **T1** – primary actions that drive progress.
- **T2** – containers and secondary controls.
- **T3** – tertiary text and filter affordances.

## Tokens
| Token | Values |
| --- | --- |
| Colors | surface, surfaceAlt, textPrimary, textSecondary, brand, success, warning, danger |
| Spacing | 4, 8, 12, 16, 20, 24, 28, 32 |
| Radius | sm, md, lg, 2xl |
| Elevation | 0, 1, 3, 6, 8 |
| Typography | title, body, label |

## Tier Mapping
| Tier | Button | Card | Chip |
| --- | --- | --- | --- |
| T1 | Primary (filled) | High elevation, lg radius | Filled |
| T2 | Secondary (outlined) | Medium elevation, md radius | Outlined |
| T3 | Ghost text | Flat, sm radius | Subtle surface |

## Usage
**Do**
- Use tokens for all spacing and colors.
- Pick tiers to match emphasis.

**Don't**
- Mix custom colors with tokens.
- Elevate T3 elements.
