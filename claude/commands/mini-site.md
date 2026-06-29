---
description: Build a single self-contained, dark-mode, interactive HTML visualization mini-site for a described subject (Preact+htm, opens by double-click).
argument-hint: <description of the subject to visualize, e.g. "our Q3 GTM plan" or "how the auth pipeline works">
---

Use the **mini-site** skill to build a single self-contained, **dark-mode**, interactive HTML visualization mini-site for this subject:

$ARGUMENTS

Follow the skill exactly:

- **One self-contained `index.html`** — inline `<style>` + one inline `<script type="module">` (data object + reusable Preact components + `render()`), only `https://esm.sh` imports. **No external local files, no `src=`, no local `import`/`export`** — this is what makes it open by double-click from `file://` (Chrome blocks local module fetches there → blank page).
- **Preact + htm via esm.sh**, pinned, no build step.
- **Dark mode, great visuals, real interactivity** — sticky jump-nav, reusable component kit (SectionHeader, Card, Pill, StatTile, FlowDiagram, Timeline, Compare, MatrixTable, inline SVG), `useState` interactions that clarify.
- Model the subject's **moving pieces** into 6–11 sections; if it references files/paths, read them for real content.
- **Verify**: `node --check` the inline module; confirm 0 local imports / 0 exports; optionally render-check via a throwaway `http.server` then kill it.
- Output to `outputs/sites/<slug>/index.html` (if an `outputs/` dir exists) else `mini-sites/<slug>/index.html`, plus a 2-line README.

Report the path and "double-click to open". Don't commit unless I ask.
