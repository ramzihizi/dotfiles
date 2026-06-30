# Near-Black Toolbar (Brave theme)

A custom Chromium theme for Brave. Brave's Settings → Appearance can't set the
toolbar and URL-bar colors independently, so this does it via a theme manifest:

- **Toolbar / window frame** — `#0a0a0a` (near black, blends into the window)
- **URL location pill** (`omnibox_background`) — `#000000` (true black, barely
  darker than the toolbar)
- **Address-bar text** (`omnibox_text`) — `#666666` (dim gray)
- **Tab / UI text** — `#d0d0d0` (soft light gray)

## Install

1. Open `brave://extensions`.
2. Enable **Developer mode** (top-right toggle).
3. Click **Load unpacked** and select this `config/brave-theme/` folder.

The theme applies immediately. To revert, open `brave://settings/appearance`
and click **Reset to default** next to Theme (or disable it in
`brave://extensions`).

## Tweaking colors

Edit `manifest.json` — colors are `[r, g, b]` arrays (0–255), not hex. After
editing, return to `brave://extensions` and click the reload (↻) icon on the
theme card to see changes.

Useful keys: `toolbar`, `frame`, `omnibox_background`, `omnibox_text`,
`tab_text`, `tab_background_text`, `bookmark_text`, `button_background`.

## Notes

- Brave may auto-disable unpacked extensions across some updates — if the colors
  revert, re-enable it in `brave://extensions`.
- This is the same mechanism Chrome Web Store themes use, just loaded unpacked so
  it can live in version control instead of the store.
