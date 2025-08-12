# Visual Style

## Story Bubbles — Visual & Behavior Spec

Geometry: 68dp outer, 3dp ring, 62dp avatar, 12sp label/600.

Unviewed ring: emerald #138A5A → gold #D4AF37 gradient.

Viewed ring: onSurfaceVariant @ 35% opacity.

"Your Story":

- No active story → add badge (18dp) bottom-right.
- Active story → no badge; same bubble geometry; ring styled like others.

View logic:

Slide has viewers: [uid,...]; owner has viewedBy: [uid,...] aggregate.

Ring state for a viewer = "unviewed" if any active slide lacks the viewer’s UID.

Note that colors derive from the Diaspora Pulse × Global Roots palette to maintain brand consistency.
