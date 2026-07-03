#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/check_forbidden_vendor_changes.sh <git-diff-range>
# Example:
#   scripts/check_forbidden_vendor_changes.sh origin/main...HEAD

RANGE="${1:-HEAD}"
FORBIDDEN_PATTERN='^(ios/Pods/|ios/Frameworks/)'

echo "[guard] checking vendor paths in diff range: ${RANGE}"

CHANGED_FILES="$(git --no-pager diff --name-only "${RANGE}" -- || true)"
FORBIDDEN_FILES="$(printf '%s\n' "${CHANGED_FILES}" | grep -E "${FORBIDDEN_PATTERN}" || true)"

if [[ -n "${FORBIDDEN_FILES}" ]]; then
  echo "::error::Forbidden third-party vendor files changed. Keep Pods/Frameworks out of app code PRs."
  echo "[guard] forbidden files:"
  printf '%s\n' "${FORBIDDEN_FILES}"
  exit 1
fi

echo "[guard] OK: no forbidden vendor path changes found."
