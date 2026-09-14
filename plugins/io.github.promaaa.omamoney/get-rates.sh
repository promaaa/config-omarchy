#!/usr/bin/env bash
# OmaMoney - Live FX rates fetcher and cache manager
set -e

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/omarchy/currency"
CACHE_FILE="$CACHE_DIR/rates.json"
MAX_AGE=3600 # 1 hour cache duration

mkdir -p "$CACHE_DIR"

fetch_live() {
  local data=""
  # Try primary API (open.er-api.com)
  data=$(curl -fsS --max-time 4 "https://open.er-api.com/v6/latest/EUR" 2>/dev/null) || true

  # Fallback to Frankfurter API
  if [ -z "$data" ]; then
    data=$(curl -fsS --max-time 4 "https://api.frankfurter.dev/v1/latest?base=EUR" 2>/dev/null) || true
  fi

  if [ -n "$data" ]; then
    echo "$data" > "$CACHE_FILE"
    return 0
  fi
  return 1
}

# Check if cache exists and is fresh
is_fresh=0
if [ -f "$CACHE_FILE" ]; then
  file_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  now=$(date +%s)
  age=$((now - file_time))
  if [ "$age" -lt "$MAX_AGE" ]; then
    is_fresh=1
  fi
fi

if [ "$is_fresh" -eq 0 ]; then
  fetch_live || true
fi

# Parse JSON with python
python3 - << 'EOF'
import json, sys, os, time

cache_file = os.path.expanduser("~/.cache/omarchy/currency/rates.json")
fallback_rates = {
    "EUR": 1.0, "KRW": 1635.65, "USD": 1.09, "JPY": 165.0, "GBP": 0.85, "CHF": 0.94, "CAD": 1.50, "AUD": 1.65, "CNY": 7.85
}

rates = fallback_rates
timestamp = int(time.time())
is_live = False

if os.path.exists(cache_file):
    try:
        with open(cache_file, "r") as f:
            data = json.load(f)
            if "rates" in data:
                rates = data["rates"]
                is_live = True
            elif "conversion_rates" in data:
                rates = data["conversion_rates"]
                is_live = True
            timestamp = int(data.get("time_last_update_unix", os.path.getmtime(cache_file)))
    except Exception:
        pass

# Ensure base is EUR 1.0
rates["EUR"] = 1.0

output = {
    "rates": rates,
    "timestamp": timestamp,
    "is_live": is_live
}

print(json.dumps(output))
EOF
