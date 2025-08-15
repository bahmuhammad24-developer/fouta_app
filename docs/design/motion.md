# Motion Guidelines

Defines animation principles for Fouta App.

## Durations
- Micro-interactions complete in **100–200 ms**.
- Page transitions last **250–300 ms** and avoid exceeding **400 ms**.

## Easing
- Use standard easing curves like `Curves.easeOut` or `Curves.easeInOut`.
- Entrance animations accelerate quickly then decelerate to a stop.

## Choreography
- Stagger related elements by **20–40 ms** to establish hierarchy.
- Align motion with content meaning; avoid gratuitous movement.

## Reduced Motion
- When the OS requests reduced motion, replace complex movement with fades or instant state changes.
