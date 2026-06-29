---
name: mini-site
description: Build a single self-contained, dark-mode, interactive HTML visualization mini-site for ANY subject — the moving pieces of a business, system, plan, concept, dataset, or decision rendered as reusable Preact components. Use when the user asks to "visualize X", "make a mini-site / viz site / dashboard for X", wants an at-a-glance interactive page of how something works, or invokes /mini-site. Bakes in the file:// gotcha so the result opens by double-click.
user-invocable: true
---

# mini-site — self-contained visual mini-sites

Turn a described subject into **one self-contained `index.html`** that visualizes its moving pieces with reusable components, dark mode, and light interactivity. Opens by double-click — no build step, no server.

## The one non-negotiable rule (this is why earlier attempts failed)

**Ship a SINGLE self-contained `index.html`. Everything inline. The only external references are `https://` CDN imports.**

Chrome **blocks `type="module"` scripts and any `./local.js` / `import "./x.js"` from `file://`** (origin `null` CORS) → the page renders **blank** on double-click. A multi-file build (`app.js` + `data.js` + `styles.css`) works over an http server but is dead on `file://`. So:

- CSS goes in an inline `<style>` in `<head>` — **no `<link rel="stylesheet">`**.
- All JS goes in **one inline `<script type="module">`** — data object + components + `render()` together. **No `src=`, no local `import`/`export`.**
- Keep ONLY the `https://esm.sh/...` imports at the top of the inline module (cross-origin https module imports ARE allowed from `file://`).

If you author it as separate files first (cleaner to write), you MUST inline-merge them into `index.html` and delete the parts before declaring done. Verify: the final file has **0 local imports, 0 `export` keywords**.

## Tech stack (decided — don't substitute)

- **Preact + htm via esm.sh, pinned, no build.** Smallest real component model (~4 KB) that injects from a header.
  ```js
  import { h, render } from "https://esm.sh/preact@10.23.1";
  import { useState } from "https://esm.sh/preact@10.23.1/hooks";
  import htm from "https://esm.sh/htm@3.1.1";
  const html = htm.bind(h);
  ```
- Plain CSS (variables for theme). No Tailwind/CDN CSS framework. Inline **SVG** for diagrams/maps/charts — no image files, no charting libs (hand-roll; it stays tiny and themeable).
- (Alternatives considered: VanJS ~1 KB is smaller but worse for many components; Alpine ~15 KB is for sprinkling markup, not a component kit. Preact+htm is the pick.)

## Output location

- Slug the subject (kebab-case, ~3 words). 
- If an `outputs/` dir exists at the repo root → `outputs/sites/<slug>/index.html`.
- Else → `mini-sites/<slug>/index.html` under the cwd.
- Also write a 2-line `README.md` next to it (what it is, "double-click to open; needs internet for the esm.sh CDN").

## Skeleton (copy this shape)

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>…</title>
    <style>/* inline theme + layout (see Dark theme below) */</style>
  </head>
  <body>
    <div id="app"></div>
    <script type="module">
      import { h, render } from "https://esm.sh/preact@10.23.1";
      import { useState } from "https://esm.sh/preact@10.23.1/hooks";
      import htm from "https://esm.sh/htm@3.1.1";
      const html = htm.bind(h);

      const data = { /* the subject, structured — drives every component */ };

      // component kit (props-driven) …
      function SectionHeader({ eyebrow, title, children }) { /* … */ }
      function App() { /* sticky nav + sections composed from data */ }

      render(html`<${App} />`, document.getElementById("app"));
    </script>
  </body>
</html>
```

## Dark theme (default look — make it genuinely good, not default-y)

- Deep near-black/slate background, light-but-not-pure text, ONE confident accent (e.g. teal `#5eead4`, violet `#a78bfa`, or amber `#fbbf24` — pick to fit the subject), plus 1–2 semantic colors (good/warn/danger).
- Card surfaces a step lighter than the bg, hairline borders, subtle shadow/glow, rounded corners (~14–16px), generous spacing, strong type hierarchy (a serif display for headings reads premium; system sans for body).
- Sticky top nav with jump-links to every section; smooth scroll; `scroll-margin-top`. Responsive grids (mobile → desktop). Respect contrast (WCAG AA) and keyboard focus.

```css
:root{
  --bg:#0d1117; --surface:#161b22; --surface-2:#1c232c; --line:#2a323d;
  --ink:#e6edf3; --ink-soft:#9aa7b4; --accent:#5eead4;
  --good:#56d364; --warn:#e3b341; --danger:#f85149;
  --radius:15px; --maxw:1080px; --shadow:0 1px 2px rgba(0,0,0,.3),0 10px 30px rgba(0,0,0,.25);
  --sans:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --serif:"Iowan Old Style","Palatino Linotype",Palatino,Georgia,serif;
}
*{box-sizing:border-box} html{scroll-behavior:smooth;scroll-padding-top:72px}
body{margin:0;background:var(--bg);color:var(--ink);font-family:var(--sans);line-height:1.55}
h1,h2,h3{font-family:var(--serif);color:#fff;line-height:1.15}
```

## Reusable component kit (build what the subject needs)

Author a small kit and reuse it; every component takes props and is fed from `data`:

- **SectionHeader** (eyebrow + title + intro), **Card**, **Pill/Badge** (status variants), **StatTile** (big number + label + note).
- **FlowDiagram** (nodes + arrows; flag a "hard"/critical node) — for entities & relationships, pipelines, money flow, request paths.
- **Timeline** (expandable steps; mark gates/milestones distinctly) — for roadmaps, sequences, lifecycles.
- **Compare / ForkCompare** (2–N column tradeoff, click-to-select drives a recommendation) — for options, A/B, vs.
- **MatrixTable** / **Grid** — for load-bearing-vs-defer, feature matrices, canvases (e.g. a 9-block Lean Canvas via CSS grid spans).
- **Inline SVG** map/diagram/mini-chart for anything spatial or quantitative.

Add **tasteful interactivity** with `useState`: expandable cards, toggles (e.g. supply/demand view), clickable comparisons that update a conclusion, hover reveals. Interactivity should clarify, not decorate.

## Content modeling — turn the subject into sections

From the user's description (and any files they point to — read them), extract the subject's **moving pieces** and map each to the right component:

| The subject has…              | Render as            |
| ----------------------------- | -------------------- |
| a thesis / one-line goal      | Hero + StatTiles     |
| entities + relationships/flow | FlowDiagram (SVG)    |
| a process / phases / roadmap  | Timeline w/ gates    |
| options / tradeoffs / a fork  | Compare              |
| a breakdown / canvas / matrix | MatrixTable / Grid   |
| key numbers / metrics         | StatTiles            |
| something spatial             | inline SVG map       |

Aim for 6–11 sections. Put the real content in the `data` object; keep components generic. Footer: generated date + source (the description, or the file path you read from).

## Build procedure

1. **Gather**: parse the `$ARGUMENTS` subject; if it references files/paths, read them for real content. Decide sections + accent color + slug.
2. **Build** the single self-contained `index.html` (inline `<style>` + inline module). For a large/rich subject, you MAY dispatch a general-purpose subagent with a detailed spec (sections + the rules in this skill) to keep main context clean — but the subagent MUST return a single self-contained file per the rule above.
3. **Verify (required):**
   - Extract the inline module to a temp `.mjs` and run `node --check` → must pass.
   - Confirm the inline module has **0 local imports** (`./`), **0 `export`** keywords, and only `https://esm.sh` imports; htm `html\`…\`` templates balanced.
   - The Chrome extension **cannot open `file://`**. To visually confirm rendering, serve briefly (`python3 -m http.server <port>`) and load `http://localhost:<port>/` (read console = 0 errors), **then kill the server**. The deliverable still must be `file://`-safe (which the single-file rule guarantees).
4. **Report**: file path, how to open ("double-click `index.html`"), component list, and any subject-specific notes. Don't commit unless asked.

## Issues we hit (so we don't lose time again)

- **Blank page on double-click** = the file:// module/CORS block above. Fix = single self-contained file. This is the #1 failure; assume it unless proven otherwise.
- A multi-file build that "passes" under Playwright/localhost will **still be blank on `file://`** — the http server masks the bug. Always end on the single-file form.
- esm.sh imports need **internet**; that's the only runtime dependency. Pin versions so the page doesn't drift/break later.
- The browser extension can't navigate to `file://` — don't try; use a throwaway localhost server for visual checks, then kill it.
- Obsidian (and some file panes) hide non-`.md` files — the html is there even if not shown; open via Finder/`open`, not the vault pane.
