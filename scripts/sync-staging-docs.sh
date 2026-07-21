#!/usr/bin/env bash
#
# Regenerate the staging docs (develop) from production (main).
#
# `develop` is a GENERATED staging mirror of `main`: it is main's content with
# every production URL rewritten to staging, plus a staging banner. Never
# hand-edit develop and never merge develop -> main. Edit docs on main (via
# feature -> main PRs), then run this script to refresh the staging docs.
#
# Usage:
#   ./scripts/sync-staging-docs.sh
#
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree not clean — commit or stash first." >&2
  exit 1
fi

git fetch origin main
git checkout develop
git pull --ff-only origin develop 2>/dev/null || true

# Take ALL content from main (overwrite), then keep develop-only infra files.
git checkout origin/main -- .
git checkout develop -- scripts/sync-staging-docs.sh .gitattributes

# Rewrite production URLs -> staging across all content + config.
find . -type f \( -name "*.mdx" -o -name "*.json" \) \
  -not -path "./node_modules/*" -not -path "./.git/*" -print0 \
  | xargs -0 perl -pi -e \
      's{https://api\.rolla\.xyz}{https://api-staging.rolla.xyz}g; s{https://app\.rolla\.xyz}{https://app-staging.rolla.xyz}g;'

# Ensure the staging banner exists in docs.json (idempotent).
node - "$PWD/docs.json" <<'NODE'
const fs = require('fs');
const f = process.argv[1];
const j = JSON.parse(fs.readFileSync(f, 'utf8'));
j.banner = {
  content: "🧪 You're viewing the **Staging** docs — base URL is `api-staging.rolla.xyz`. For production, see [docs.rolla.xyz](https://docs.rolla.xyz).",
  dismissible: true,
};
fs.writeFileSync(f, JSON.stringify(j, null, 2) + "\n");
NODE

node -e "JSON.parse(require('fs').readFileSync('docs.json','utf8')); JSON.parse(require('fs').readFileSync('api-reference/openapi.json','utf8'));" \
  && echo "✓ JSON valid"

git add -A
if git diff --cached --quiet; then
  echo "Staging docs already in sync with main."
else
  git commit -m "chore: regenerate staging docs from main (swap prod URLs to staging)"
  git push origin develop
  echo "✓ Staging docs updated and pushed."
fi
