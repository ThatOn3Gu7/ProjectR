#!/usr/bin/env bash
#
# deploy-docs.sh
#
# Builds the docs webapp and syncs the production output into the repo's
# `docs/` directory, replacing the previous single-file LandingPage with the
# modern React app (plus its hashed JS/CSS assets and favicon).
#
# The webapp lives in `<repo>/projectr-docs-webapp/` and is published to the
# root `/docs` folder so it can be served statically from `docs/index.html`.
#
# Usage:
#   bash scripts/deploy-docs.sh          # build + sync
#   bash scripts/deploy-docs.sh --copy   # sync only (assumes dist/ is fresh)
#
# Prerequisites:
#   npm run build      # normally invoked first via `npm run deploy:docs`
set -euo pipefail

# ── Locate directories ──────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBAPP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${WEBAPP_DIR}/.." && pwd)"

DIST_DIR="${WEBAPP_DIR}/dist"
DOCS_DIR="${REPO_DIR}/docs"

# ── Pick a package runner (prefer pnpm, fall back to npm) ────────────────
if command -v pnpm >/dev/null 2>&1; then
  RUNNER="pnpm"
else
  RUNNER="npm"
fi

# ── Build unless we're in copy-only mode ──────────────────────────────────
if [[ "${1:-}" != "--copy" ]]; then
  echo "▸ Building docs site (tsc + vite) via ${RUNNER}..."
  (cd "${WEBAPP_DIR}" && "${RUNNER}" run build)
fi

# ── Guard: dist must exist ────────────────────────────────────────────────
if [[ ! -d "${DIST_DIR}" ]]; then
  echo "✗ Build output not found at ${DIST_DIR}" >&2
  echo "  Run 'npm run build' first (or drop the --copy flag)." >&2
  exit 1
fi

mkdir -p "${DOCS_DIR}"

# ── Clean previous webapp artifacts from /docs ─────────────────────────────
# Remove the old single-page file and any prior build output we own, while
# leaving the packaged Markdown docs intact.
rm -f "${DOCS_DIR}/index.html" "${DOCS_DIR}/Index.html" "${DOCS_DIR}/favicon.svg"
rm -rf "${DOCS_DIR}/assets"
rm -rf "${DOCS_DIR}/dist-ssr"

# ── Sync build output → /docs ──────────────────────────────────────────────
cp "${DIST_DIR}/index.html"        "${DOCS_DIR}/index.html"
cp -R "${DIST_DIR}/assets"         "${DOCS_DIR}/assets"
[[ -f "${DIST_DIR}/favicon.svg" ]] && cp "${DIST_DIR}/favicon.svg" "${DOCS_DIR}/favicon.svg"

echo "✓ Deployed docs site to ${DOCS_DIR}"
echo "  - index.html"
echo "  - $(find "${DOCS_DIR}/assets" -type f | wc -l | tr -d ' ') asset(s)"
[[ -f "${DOCS_DIR}/favicon.svg" ]] && echo "  - favicon.svg"