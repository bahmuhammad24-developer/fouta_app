Fixed CI failures caused by npm ci strictness in functions/.

Added resilient install step: try npm ci --omit=dev; if it fails, fallback to npm install --omit=dev.

Documented the policy and the stricter alternative (commit lockfile).

