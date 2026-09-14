#!/usr/bin/env python3
"""
Helper script to save OmaMoney configuration to ~/.config/omarchy/omamoney.json
"""
import sys
import json
from pathlib import Path

CONFIG_PATH = Path.home() / ".config" / "omarchy" / "omamoney.json"

def main():
    if len(sys.argv) < 2:
        sys.exit(1)
    
    raw = sys.argv[1]
    try:
        data = json.loads(raw)
        CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(CONFIG_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print("ok")
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
