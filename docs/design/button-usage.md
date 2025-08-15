# Button usage

Use `FoutaButton` for consistent Tier-2 buttons. Styles map to the current theme's
colour scheme and should be chosen based on action importance.

| Style | When to use | Example |
| --- | --- | --- |
| **Primary** (filled) | The main call-to-action on a screen | `Buy` on product detail, `Support Creator` on seller profile |
| **Secondary** (outlined) | Supporting actions | `Message Seller` on product detail, `Cancel` in post preview |
| **Tertiary** (text) | Low emphasis link-style actions | none in this pass |
| **Destructive** | Actions that remove data or have irreversible effects; use `colorScheme.error` colours | none in this pass |

## Examples
- Product detail: `FoutaButton(label: 'Buy', primary: true)`
- Seller profile: `FoutaButton(label: 'Message seller', primary: false)`
- Create post preview: `FoutaButton(label: 'Post', primary: true)`
- Create post preview: `FoutaButton(label: 'Cancel', primary: false)`
