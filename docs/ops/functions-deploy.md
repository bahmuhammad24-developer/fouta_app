# Cloud Functions Deploy – Dependency Install Strategy

**Why we changed this**
- CI used `npm ci` inside `functions/`. This is strict and requires `functions/package-lock.json`
  to be present and exactly in sync with `package.json`.
- When the lockfile is missing or stale, `npm ci` fails with errors like:
  `npm ci can only install packages when your package.json and package-lock.json are in sync…`

**Policy**
- In CI we attempt:
  1. `npm ci --omit=dev --no-audit --no-fund`
  2. If that fails, fall back to `npm install --omit=dev --no-audit --no-fund`.
- We always omit dev dependencies for smaller/faster production builds.

**Recommended (stricter) alternative**
- Regenerate and commit a lockfile for functions:
  ```bash
  cd functions
  rm -f package-lock.json
  npm install        # produces fresh package-lock.json
  git add package-lock.json
  git commit -m "chore(functions): refresh lockfile"
  ```
  After that, CI will use the fast path (npm ci --omit=dev) reliably.

**Notes on native/optional deps (e.g., sharp, ffmpeg)**

Firebase Functions install on Google’s build environment; --omit=dev is safe for production.

If a dependency must be available at runtime, keep it in dependencies (not devDependencies).

