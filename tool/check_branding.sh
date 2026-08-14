#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

legacy_brand='J'"Flutter"
legacy_lower='j'"flutter"
legacy_upper='J'"FLUTTER"
legacy_pattern="${legacy_brand}|${legacy_lower}|${legacy_upper}"

path_matches="$(
  while IFS= read -r -d '' path; do
    if [ -e "$REPO_ROOT/$path" ] && [[ "$path" =~ $legacy_pattern ]]; then
      printf '%s\n' "$path"
    fi
  done < <(
    git -C "$REPO_ROOT" ls-files --cached --others --exclude-standard -z
  )
)"
if [ -n "$path_matches" ]; then
  echo "Legacy brand found in tracked paths:" >&2
  echo "$path_matches" >&2
  exit 1
fi

content_matches="$(
  git -C "$REPO_ROOT" grep --untracked -nEI "$legacy_pattern" -- . \
    ':(exclude)docs/BRANDING.md' \
    ':(exclude)release/APP_STORE_CONNECT_RECORDS.md' \
    ':(exclude)release/APPLE_QA_MATRIX.md' \
    ':(exclude)release/MACOS_QA_CHECKLIST.md' || true
)"

allowed_pattern="https://github\\.com/ThalesMMS/(${legacy_brand}-dev|${legacy_brand}|${legacy_lower})|https://thalesmms\\.github\\.io/${legacy_brand}|ThalesMMS/${legacy_brand}-dev|ThalesMMS/${legacy_brand}"
unexpected_matches="$(printf '%s\n' "$content_matches" | grep -Ev "$allowed_pattern" || true)"

if [ -n "$unexpected_matches" ]; then
  echo "Legacy brand found outside compatibility-only references:" >&2
  echo "$unexpected_matches" >&2
  exit 1
fi

echo "Turing Lab branding audit passed"
