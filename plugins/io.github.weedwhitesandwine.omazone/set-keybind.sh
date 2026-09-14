#!/usr/bin/env bash
set -euo pipefail

NEWCOMBO="${1:?usage: set-keybind.sh \"SUPER + X\"}"
FILE="$HOME/.config/hypr/bindings.lua"
MARKER='omarchy-shell shell toggle io.github.weedwhitesandwine.omazone'

if [ ! -f "$FILE" ]; then
  echo "ERROR: $FILE not found" >&2
  exit 2
fi

BACKUP="$FILE.bak.$(date +%s)"
cp "$FILE" "$BACKUP"

if grep -qF "$MARKER" "$FILE"; then
  awk -v marker="$MARKER" -v combo="$NEWCOMBO" '
    index($0, marker) {
      sub(/o\.bind\("[^"]*"/, "o.bind(\"" combo "\"")
    }
    { print }
  ' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
else
  cat <<EOF >> "$FILE"

-- Omazone multi-timezone popup
o.bind("$NEWCOMBO", "Omazone", "$MARKER")
EOF
fi

hyprctl reload >/dev/null

ERRS="$(hyprctl configerrors)"
if [ -n "$ERRS" ]; then
  cp "$BACKUP" "$FILE"
  hyprctl reload >/dev/null
  echo "ERROR: $ERRS" >&2
  exit 1
fi

echo "OK: $NEWCOMBO"
