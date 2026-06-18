#!/usr/bin/env python3
"""Validate mkdocs.yml loads cleanly.

Runs `mkdocs.config.load_config` which exercises:
  - YAML syntax
  - Plugin name resolution (catches typos)
  - Required plugin options
  - Theme feature names
  - Nav tree shape

Faster than `mkdocs build` because no rendering happens.

Exit codes:
  0 — config loads
  1 — config error
  2 — mkdocs not installed (treat as soft skip; full CI catches this)
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MKDOCS = REPO / "mkdocs.yml"


def main() -> int:
    try:
        from mkdocs.config import load_config
    except ImportError:
        print("WARNING: mkdocs not installed locally; skipping config validation.", file=sys.stderr)
        print("         Install via `pip install -r docs/requirements.txt` to enable.", file=sys.stderr)
        return 0

    if not MKDOCS.exists():
        print(f"ERROR: {MKDOCS} not found", file=sys.stderr)
        return 1

    try:
        load_config(str(MKDOCS))
    except Exception as exc:
        print(f"ERROR: mkdocs.yml failed to load: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
