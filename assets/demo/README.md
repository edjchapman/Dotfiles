# Demo

`bootstrap.tape` is a [vhs](https://github.com/charmbracelet/vhs) script. Running it produces `bootstrap.gif` — a deterministic recording of the bootstrap + drift-check flow.

## Render

```bash
brew install vhs
vhs assets/demo/bootstrap.tape
```

Re-render after any edit to `bootstrap.tape`. The output GIF is committed alongside the tape so PR review covers both the source script and the rendered artifact.

## Why vhs (and not asciinema)

vhs produces deterministic recordings from a text script that diffs cleanly in PRs. asciinema requires manual capture, then a separate post-processing step through `svg-term-cli` to get an embeddable artifact — and the captured cast file is opaque to review. See [ADR-0004](../../docs/decisions/0004-rebrand-public-showcase.md) for the full rationale.

## Sanitization

The tape script sets `HOME=/tmp/demo` before recording, so no real `~/edjchapman/` paths appear in any frame. Don't change that line — every frame of the published GIF must be safe to share.
