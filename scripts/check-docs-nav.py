#!/usr/bin/env python3
"""Check every docs/*.md is either in mkdocs.yml nav or an explicit allowlist.

Run as a pre-commit hook to catch orphan pages that would render but never
appear in navigation. A nav-only page is also flagged (entry references a
missing file).

Allowlisted paths (relative to docs/) are not required to appear in nav:
- includes/  — pymdownx.snippets fragments
- assets/    — images, CSS, JS

Exit codes:
  0 — all docs accounted for
  1 — orphans or missing-file refs found
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MKDOCS = REPO / "mkdocs.yml"
DOCS = REPO / "docs"

ALLOWLIST_PREFIXES = ("includes/", "assets/", "stylesheets/", "javascripts/", "overrides/")


def safe_yaml_load(text: str):
    """Load YAML, ignoring unknown !!python/name: tags used by mkdocs extensions."""
    try:
        import yaml
    except ImportError:
        print("ERROR: PyYAML is required. Install via `pip install pyyaml`.", file=sys.stderr)
        sys.exit(2)

    class _Loader(yaml.SafeLoader):
        pass

    def _ignore_unknown(loader, tag_suffix, node):
        return None

    _Loader.add_multi_constructor("tag:yaml.org,2002:python/name:", _ignore_unknown)
    _Loader.add_multi_constructor("!!python/name:", _ignore_unknown)
    return yaml.load(text, Loader=_Loader)


def collect_nav_paths(nav, out: set[str]) -> None:
    """Recursively collect all .md paths referenced in the nav tree."""
    if isinstance(nav, list):
        for item in nav:
            collect_nav_paths(item, out)
    elif isinstance(nav, dict):
        for value in nav.values():
            if isinstance(value, str) and value.endswith(".md"):
                out.add(value)
            else:
                collect_nav_paths(value, out)
    elif isinstance(nav, str) and nav.endswith(".md"):
        out.add(nav)


def main() -> int:
    if not MKDOCS.exists():
        print(f"ERROR: {MKDOCS} not found", file=sys.stderr)
        return 2

    config = safe_yaml_load(MKDOCS.read_text())
    nav = config.get("nav", []) if config else []
    nav_paths: set[str] = set()
    collect_nav_paths(nav, nav_paths)

    on_disk = {
        str(p.relative_to(DOCS))
        for p in DOCS.rglob("*.md")
        if not any(str(p.relative_to(DOCS)).startswith(prefix) for prefix in ALLOWLIST_PREFIXES)
    }

    orphans = sorted(on_disk - nav_paths)
    missing = sorted({p for p in nav_paths if not (DOCS / p).exists()})

    if orphans:
        print("ERROR: docs files on disk but not in nav:", file=sys.stderr)
        for p in orphans:
            print(f"  - docs/{p}", file=sys.stderr)
        print(
            "Hint: either add the page to nav in mkdocs.yml, "
            "or move it under docs/includes/ if it is a snippet.",
            file=sys.stderr,
        )

    if missing:
        print("ERROR: nav references missing files:", file=sys.stderr)
        for p in missing:
            print(f"  - docs/{p}", file=sys.stderr)

    return 1 if (orphans or missing) else 0


if __name__ == "__main__":
    sys.exit(main())
