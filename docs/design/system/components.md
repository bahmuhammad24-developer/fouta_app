# Components

Core UI building blocks should follow the tokens defined in `tokens.json` and expose consistent states.

## Button
- **States:** default, hover, focus, pressed, disabled
- **Usage:** triggers primary actions; use filled for main call to action and outlined for secondary.
- **Accessibility:** label every button; touch target ≥44dp.

## IconButton
- **States:** default, hover, focus, pressed, disabled
- **Usage:** use for compact icon-only actions; avoid textless buttons for critical tasks.
- **Accessibility:** provide `aria-label`/tooltip; hit-target ≥44dp.

## TextField
- **States:** default, hover, focus, disabled, error
- **Usage:** use for single-line input; pair labels and helper text for clarity.
- **Accessibility:** persistent label and described-by helper/error text.

## Checkbox
- **States:** unchecked, checked, hover, focus, disabled
- **Usage:** toggle multiple selections in lists or forms.
- **Accessibility:** label each checkbox; hit-target ≥44dp.

## Switch
- **States:** off, on, hover, focus, disabled
- **Usage:** binary settings that take effect immediately.
- **Accessibility:** label with current state; ensure 44dp minimum size.

## Card
- **States:** default, hover, focus, pressed
- **Usage:** group related content and actions; use elevation tokens for hierarchy.
- **Accessibility:** ensure content order is logical; tap area ≥44dp.

## Dialog
- **States:** default, hover, focus, pressed (within), disabled (actions)
- **Usage:** interruptive messaging for critical decisions or inputs.
- **Accessibility:** trap focus within dialog, provide descriptive titles and buttons.

All interactive components must honor the tokens and spacing defined in the design system for a cohesive experience.
