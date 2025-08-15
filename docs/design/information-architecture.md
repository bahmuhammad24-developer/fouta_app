# Information Architecture & Navigation Model

## Primary Sections
- **Home** – algorithmic feed of posts and commerce updates.
- **Marketplace** – browse, search, and manage product listings.
- **Create** – unified entry point for posting content or listing items.
- **Messages** – direct conversations and transaction chats.
- **Profile** – user profile, settings, and saved items.

## Contextual Actions
- Prefer a **contextual floating action button (FAB)** when a screen has one dominant primary action.
- Use an **overflow menu** when multiple secondary actions exist or when a primary action would clutter the layout.
- Examples:
  - *Home*: FAB opens the create composer; overflow contains feed preferences.
  - *Marketplace*: FAB starts a new listing; overflow manages filters or saved searches.
  - *Messages*: FAB starts a new message thread.
  - *Profile*: Overflow holds edit and share actions.

## Deep‑Link & Back‑Stack Rules
- Deep links land users on the target screen with minimal intermediate routes.
- Navigating between the five primary sections resets the stack for that section.
- Nested flows push onto the stack; the system back button pops to the previous screen.
- Backing out from a root section exits the app or returns to the invoking app.
- When re‑entering via a notification or deep link, preserve any in‑progress edits or drafts.
