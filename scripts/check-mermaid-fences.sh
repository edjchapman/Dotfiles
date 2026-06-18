#!/usr/bin/env bash
# Check every ```mermaid fenced code block opens with a recognised diagram type.
# Catches typos like ```mermaid\nflowchat TD that mkdocs renders as a broken
# "Syntax error" SVG client-side without failing the build.

set -euo pipefail

# Valid declarations as of mermaid v11. Add new types here when adopting them.
VALID="flowchart graph sequenceDiagram classDiagram stateDiagram stateDiagram-v2 erDiagram journey gantt pie mindmap timeline gitGraph quadrantChart requirementDiagram C4Context C4Container C4Component C4Dynamic sankey-beta xychart-beta block-beta packet-beta architecture-beta"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

if [[ $# -eq 0 ]]; then
    mapfile -t files < <(find docs -name '*.md' -type f 2>/dev/null)
else
    files=("$@")
fi

is_valid_declaration() {
    local first_word="$1"
    for v in $VALID; do
        [[ "$first_word" == "$v" ]] && return 0
    done
    return 1
}

fail=0
for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue

    in_block=0
    line_no=0
    awaiting_decl=0
    while IFS= read -r line; do
        line_no=$((line_no + 1))
        if [[ "$line" =~ ^\`\`\`mermaid[[:space:]]*$ ]]; then
            in_block=1
            awaiting_decl=1
            continue
        fi
        if [[ "$in_block" -eq 1 && "$line" =~ ^\`\`\`[[:space:]]*$ ]]; then
            in_block=0
            awaiting_decl=0
            continue
        fi
        if [[ "$awaiting_decl" -eq 1 ]]; then
            # Skip blank lines and %% comments inside the block.
            [[ -z "${line// /}" ]] && continue
            [[ "$line" =~ ^[[:space:]]*%% ]] && continue

            # First substantive line — extract the first word.
            first_word="${line%% *}"
            first_word="${first_word%$'\r'}"
            if ! is_valid_declaration "$first_word"; then
                echo "ERROR: $f:$line_no — unrecognised mermaid diagram declaration: $line" >&2
                fail=1
            fi
            awaiting_decl=0
        fi
    done <"$f"
done

if [[ $fail -ne 0 ]]; then
    echo "Hint: valid declarations are flowchart, sequenceDiagram, stateDiagram-v2, graph, classDiagram, erDiagram, journey, gantt, pie, mindmap, timeline, gitGraph, quadrantChart, etc." >&2
    exit 1
fi
