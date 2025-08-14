# DEP: vitest
Date: 2025-08-14
Author: AI
Status: Adopted

## Purpose
Run Cloud Function unit tests with fast TypeScript support.

## Package
- Name: vitest
- Link: https://vitest.dev
- License: MIT

## Alternatives considered
- jest — slower startup
- mocha — requires additional setup

## Platform impact
- Android: none
- iOS: none
- Web: none

## Data, privacy & security
No network calls; dev-only test framework.

## Test & rollout plan
`npm test` in CI to execute unit tests.

## Removal plan
Remove devDependency and related test scripts.
