# Omazone

A multi-timezone clock for [Omarchy](https://omarchy.org/) that displays live timezone clocks directly on your top status bar and drops down an interactive time-travel panel when clicked. Track any number of cities, each with its own icon and label, and drag the Time Travel slider to see what time it'll be everywhere at once.

![Omazone open, showing tracked cities](preview.png)

## Features

- **Live Top-Bar Clocks** — see your chosen timezones right on the status bar (e.g. `🇫🇷 09:32  🇰🇷 16:32  🇲🇽 01:32`). Compact, lightweight, and takes minimal space.
- **Collapse to Globe Icon (󰖟)** — easily toggle between showing full timezone clocks or collapsing to a minimal globe icon on the bar, so it always remains clickable and accessible.
- **Multiple Bar Display Styles**:
  - `Compact (Flags)`: Flag/emoji + time (`🇫🇷 09:32 · 🇰🇷 16:32 · 🇲🇽 01:32`).
  - `Airport Codes`: 3-letter city codes (`PAR 09:32 · SEL 16:32 · MEX 01:32`).
  - `City Names`: Custom city labels (`Paris 09:32 · Seoul 16:32 · Mexico 01:32`).
  - `Single Zone (Cycling)`: Displays one zone at a time and cycles every 5 seconds.
  - `Globe Icon Only`: Minimal single globe icon (`󰖟`).
- **Comprehensive Timezone Coverage** — full support for Mexican timezones (`America/Mexico_City`, `America/Cancun`, `America/Tijuana`, `America/Monterrey`, `America/Hermosillo`, etc.), French, Korean, US, European, and worldwide IANA timezones.
- **Rich Bar Tooltip** — hover over the bar widget to see full city names, local times, timezone abbreviations, and UTC offsets.
- **Interactive Bar Controls**:
  - *Left click*: Open / close the Time Travel dropdown panel.
  - *Middle click*: Cycle through bar display styles.
  - *Right click*: Quick toggle between 12-hour and 24-hour time format.
  - *Mouse wheel*: Cycle active zone when in cycling mode.
- **Time Travel slider** — drag it and every tracked city's clock updates together, so you can preview a meeting time or a future moment across all of them at once. Shows a +1/−1 badge when a city has rolled into a different calendar day.
- **Customizable icons & labels** — edit icons (flags or emoji) and labels for each city.
- **Rebindable Keybind** — set your shortcut (e.g. `SUPER + I`) from the settings view with safety validation.

## Install

```bash
omarchy plugin add https://github.com/promaaa/omazone.git --enable
```

Run in a real terminal, this asks which bar section to place the widget in (left/center/right, center or right pre-selected) before enabling it. Change your mind later with:

```bash
omarchy bar move io.github.weedwhitesandwine.omazone --section center
```

Add a keybind, e.g. in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + I", "Toggle Omazone", "omarchy-shell shell toggle io.github.weedwhitesandwine.omazone")
```

(Or configure it directly in the panel settings view.)

## Remove

```bash
omarchy plugin remove io.github.weedwhitesandwine.omazone
```

This deletes the plugin and cleans up its bar widget automatically. Your tracked cities and settings stay on disk at `~/.local/state/omarchy/omazone/` unless you remove that directory too.

## Usage

- **Open/close**: your keybind (default `SUPER + I`), clicking the bar widget (clocks or globe icon), or `omarchy-shell shell toggle io.github.weedwhitesandwine.omazone`.
- **Bar quick-actions**:
  - Left click: toggle panel
  - Middle click: cycle bar display styles (`Compact` -> `Codes` -> `Names` -> `Cycle`)
  - Right click: toggle 12h/24h time format
- **Show clocks vs Globe icon**:
  - In the panel header: click the globe / clock toggle icon to switch between expanded timezone clocks and the minimal globe icon with 1 click.
  - In Settings: toggle "Show clocks on status bar".
  - Via CLI: `omarchy-shell io.github.weedwhitesandwine.omazone toggleClocks`.
- **Click the gear icon (⚙)** in the panel header to open settings:
  - **Bar Display** — toggle clocks display, choose display style, toggle globe icon prefix, or toggle +1/−1 day offset badges.
  - **Cities** — search and check off any number of timezones to track.
  - **Format** — 12-hour or 24-hour time.
  - **Keybind** — record a new shortcut (with one modifier) and apply it safely.
- **City row actions**: `↑`/`↓` reorder, `✎` edit icon and label, `✕` remove.
- **Time Travel slider**: ranges from -24h to +48h. The reset icon (⟲) jumps back to now.

## External dependencies and system-level modifications

This plugin runs `bash`, `date`, `timedatectl`, `jq`, and `hyprctl` via Quickshell's `Process` — standard on any Omarchy install with no extra packages needed. Times are computed offline using system tzdata.

## State files

- `~/.local/state/omarchy/omazone/settings.json` — tracked cities, custom icons/labels, 12/24-hour preference, bar style, showClocksOnBar, and keybind.

## License

MIT — see [LICENSE](LICENSE).
