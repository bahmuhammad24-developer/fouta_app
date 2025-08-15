# Ranking

## Hot Formula
```
score = ups - downs
hot = log10(max(abs(score), 1)) + sign(score) * (age_hours / DECAY_HOURS)
DECAY_HOURS ∈ [48,72]
```

## Rising
Composite of vote velocity and comment velocity within <24h

## Top
Day, week, month, and all-time windows with server-side filters

## Anti-gaming
- Per-user vote caps/timebox
- IP/device throttling
- New account weighting
- Shadow-ban
- Brigading detector (ratio + burst)
