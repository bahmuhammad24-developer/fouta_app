# Data Model

## Challenge Schema
```ts
id: string
title: string (<=140)
description: string (<=10k)
tags: string[]
authorId: string
createdAt: timestamp
editedAt: timestamp?
visibility: 'public'|'flagged'
status: 'open'|'in_progress'|'solved'
location?: { country: string, city?: string, lat?: number, lng?: number }
links?: { title: string, url: string }[]
score: number // ups - downs
upvoters: string[] // optional lightweight store; server should tally
downvoters: string[]
commentCount: number
followers: string[] // optional
```

## Comment Schema (flat or depth=1 reply)
```ts
id: string
challengeId: string
authorId: string
body: string
createdAt: timestamp
score: number
upvoters: string[]
downvoters: string[]
```

## Tag Taxonomy
- **Sector:** e.g., health, education, transport
- **Topic:** e.g., potholes, water access, recycling
- **Region:** e.g., West Africa, Lagos, EU
- **SDG:** e.g., `sdg-3`, `sdg-11`

## Denormalizations
- Store `tagKeys` (lowercased slugs) for querying
- Store `createdAtDay` for date range filters
