# Firebase CI Notes

- Use `npm install --no-audit --no-fund` in CI for Cloud Functions to tolerate `package-lock.json` drift that may occur locally.
- Cache `functions/node_modules` with a key derived from `sha256sum functions/package.json` to avoid redundant installs.
- Skip Cloud Functions deploy entirely when `git diff --quiet HEAD~1 -- functions/` finds no changes; rules, indexes, and storage deploy remain unaffected.

