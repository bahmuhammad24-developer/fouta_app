# Layout

Guidelines for arranging content consistently across platforms.

## Grid
- Base spacing uses a 4 dp unit with 8 dp keylines.
- Content columns expand in multiples of 4 dp.
- Use tokens for spacing and elevation to maintain rhythm.

## Safe Areas
- Respect platform safe areas (status bar, notches, system gestures).
- Avoid placing interactive elements within unsafe regions.

## Breakpoints
Responsive layouts adapt at the following widths:

| Size | Range (px) | Columns |
|------|------------|---------|
| Small | <600 | 4 |
| Medium | 600–1023 | 8 |
| Large | ≥1024 | 12 |

Layout should fluidly adapt between breakpoints while preserving readable line lengths and adequate touch targets.
