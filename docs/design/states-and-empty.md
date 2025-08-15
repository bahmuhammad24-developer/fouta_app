# UI States: Loading, Empty, Error

Consistent states make the app feel responsive and intentional.

## Loading
- Show lightweight **skeleton placeholders** that hint at structure.
- Avoid spinners for lists unless content length is unknown.

## Empty
- Provide friendly, concise copy.
- Pair with a clear call to action when possible.
- Example: "No listings yet" with a button to create one.

## Error
- Use plain language and suggest a next step.
- Example: "Couldn't load messages. Pull to retry.".

## Skeleton Examples
- Post card: gray boxes for avatar, media, and text lines.
- Marketplace grid: square tile placeholders matching item cards.

## Copy Guidelines
- Keep titles under 45 characters.
- Use sentence case and avoid blaming the user.
- Offer remediation when actionable; otherwise acknowledge the state.
