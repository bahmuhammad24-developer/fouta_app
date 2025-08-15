#!/usr/bin/env bash
set -euo pipefail
PROJECT="${1:-fouta-app}"
echo "Deploying to $PROJECT ..."
firebase deploy --only firestore:rules,firestore:indexes,storage,functions --project "$PROJECT"
