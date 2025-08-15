# Navigation and FAB Placement

## Overview
This document summarizes the placement of bottom navigation items and floating action buttons (FABs).

## Current Placement
- **Feed**
  - FAB: Create Post
  - Purpose: quick entry to post composer from anywhere in feed.
- **Chat**
  - FAB: Start New Chat
  - Purpose: shortcut to new conversation flow.
- **Events**
  - No FAB. Creation handled within screen.
- **People**
  - No FAB to prevent feature crowding.
- **Profile**
  - No FAB. Editing actions live in contextual menus.

## Rationale
- Aligns with use case flow: primary tasks surfaced within relevant tabs.
- Avoids feature crowding by limiting FABs to high-frequency actions.
- Prioritizes speed for top tasks (posting, messaging) without duplicating AppBar actions.

## Future Considerations
- Marketplace tab may introduce a "Create Listing" FAB following the same guidelines.
