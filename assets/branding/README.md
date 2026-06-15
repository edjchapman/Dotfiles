# Branding assets

Source-of-truth files for the repo's visual identity. The `.svg` files are the editable source; the `.png` files are the GitHub-served artifacts.

| File | Dimensions | Used for |
|---|---|---|
| `hero.svg` / `hero.png` | 1200 × 320 | Top of `README.md` |
| `social-preview.svg` / `social-preview.png` | 1280 × 640 | GitHub social preview (Settings → Social preview) |

## Re-exporting PNG from SVG

`rsvg-convert` (from `librsvg`, installed via Homebrew) is the canonical rasterizer.

```bash
# Hero
rsvg-convert -w 1200 -h 320 hero.svg > hero.png

# Social preview
rsvg-convert -w 1280 -h 640 social-preview.svg > social-preview.png
```

If you tweak an SVG, regenerate the PNG in the same PR so the two stay in sync. If `rsvg-convert` is missing: `brew install librsvg`.

## Uploading the social preview

GitHub does not expose social-preview image upload via the REST API. The image must be set manually:

1. Open <https://github.com/edjchapman/dotfiles/settings>.
2. Scroll to **Social preview**.
3. Drag `social-preview.png` onto the upload area.
4. Verify via <https://opengraph.dev/?url=https://github.com/edjchapman/dotfiles> or the Twitter Card Validator.

Re-upload after any edit to `social-preview.svg`.
