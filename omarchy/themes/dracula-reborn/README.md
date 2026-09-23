# Omarchy Dracula Reborn Theme

*Enter freely. Leave the daylight at the door.*

The Count has returned, and found the old house in need of renovation. **Dracula Reborn** brings the canonical Dracula Classic colors to **Omarchy 4 — Quattro**, interpreted into Base24: purple velvet, pink candlelight, green phosphor, and a familiar charcoal night. No borrowed bloodline. No gratuitous red wash. You know these colors; they have merely acquired new chambers.

This is a community interpretation of Dracula, not an official Dracula Base24 release.

## Preview

![Dracula Reborn desktop preview](preview.png)

The existing preview artwork was made under the theme’s former name, Flat Dracula. The palette and wallpapers carry forward; Quattro generates the shell and supported app styling from the palette, so individual details may change with Omarchy updates.

## Install

### An invitation to the house

Requires **Omarchy 4 / Quattro**. Use the Omarchy theme installer:

```bash
omarchy theme install https://github.com/OldJobobo/omarchy-dracula-reborn-theme
```

The installer applies the theme. The former Flat Dracula repository is not the install target for this edition.

### Local development

To use an existing checkout instead, run these commands **from this repository’s root**:

```bash
mkdir -p ~/.config/omarchy/themes
ln -s "$PWD" ~/.config/omarchy/themes/dracula-reborn
omarchy theme set dracula-reborn
```

Keep this checkout in place: the installed entry points to it. If `dracula-reborn` already exists in your themes directory, inspect it before proceeding; do not overwrite another installation.

Applying the theme changes the active desktop theme and may change the wallpaper. After editing the source of the active theme, use `omarchy theme refresh` to regenerate it without cycling the background.

## The bloodline

The old colors remain the law of the house.

| Dracula color | Hex |
| --- | --- |
| Background | `#282A36` |
| Foreground | `#F8F8F2` |
| Selection | `#44475A` |
| Comment | `#6272A4` |
| Purple | `#BD93F9` |
| Pink | `#FF79C6` |
| Cyan | `#8BE9FD` |
| Green | `#50FA7B` |
| Yellow | `#F1FA8C` |
| Orange | `#FFB86C` |
| Red | `#FF5555` |

`colors.toml` supplies Omarchy’s semantic palette. The full 24-slot mapping is preserved in `flat-dracula-base24.yaml`, which retains its original filename and palette name.

Base24 gives Dracula’s darker backgrounds and bright ANSI colors explicit places alongside the core palette. Purple occupies the blue role; pink occupies magenta. Comment and Foreground are intentionally reused for the additional foreground slots. The one noncanonical color is `base0F`, a derived maroon (`#993333`) adopted from Tinted Theming’s Dracula mapping.

![Dracula Base24 palette with labeled hexadecimal swatches](preview-palette.png)

## What's Included

- **The Base24 interpretation**, mapped into Omarchy’s native palette roles.
- **Four 6K wallpapers**: Hero, Pattern, Quiet, and Omarchy branding.
- **Boot-unlock artwork**, for a proper greeting before the desktop wakes.
- **Optional app styling**, including a Dracula-flavored Vencord theme based on Midnight, with sharp corners, plus Steam and command-line extras.
- **Dracula editor preferences** for local use: the Dracula Neovim plugin and VS Code extension.

The house does not keep two servants for the same task. Terminal, shell, btop, Helix, Obsidian, Pi, browser, keyboard, share-picker, and generated VS Code colors are left to Omarchy’s templates rather than frozen copies in this repository. User template overrides can affect the result.

## Wallpapers

### The grounds, after sundown

<table>
  <tr>
    <td><img src="backgrounds/flat-dracula-hero.webp" width="420" alt="Hero: castle, ornate window tracery, and a foreground stag"><br><strong>Hero</strong> — the castle receives its guest.</td>
    <td><img src="backgrounds/flat-dracula-pattern.webp" width="420" alt="Pattern: arches, wings, moons, and stars"><br><strong>Pattern</strong> — something for the drawing room.</td>
  </tr>
  <tr>
    <td><img src="backgrounds/flat-dracula-quiet.webp" width="420" alt="Quiet: crescent moon, bats, and mountain silhouettes"><br><strong>Quiet</strong> — the valley has gone to sleep.</td>
    <td><img src="backgrounds/omarchy.webp" width="420" alt="Omarchy wordmark in Dracula purple on charcoal"><br><strong>Omarchy</strong> — the family crest, suitably dressed.</td>
  </tr>
</table>

All four are **6144 × 3456**, lossless WebP. Choose them through Omarchy’s background picker; the session lock screen uses the selected wallpaper. Hero, Pattern, and Quiet carry a small artist insignia. The Omarchy wallpaper stays unsigned.

`preview-wallpapers.png` is a presentation sheet, not an additional wallpaper. Nine earlier wallpapers remain in `old-backgrounds/`, outside the active rotation.

### Before the gates open

![Dracula Reborn boot-unlock artwork preview](preview-unlock.png)

`unlock.png` supplies the transparent boot/disk-unlock logo. Select this theme separately with:

```bash
omarchy plymouth switcher
```

Changing the desktop theme does **not** apply boot branding. The image above is a rendered preview, not a live screenshot.

## Optional company

Bundled app files are not a promise of automatic installation. Fish/FZF, Cava, GTK, Lazygit, Starship, Steam, and Vencord assets need the appropriate app configuration or integration. The Vencord stylesheet imports Midnight remotely.

`icons.theme` requests **Yaru-purple**; the icon pack itself is not bundled.

For the optional Starship prompt, back up your existing configuration before copying `starship.toml`. From this repository’s root:

```bash
mkdir -p ~/.config
if [ -e ~/.config/starship.toml ]; then
  cp -a ~/.config/starship.toml ~/.config/starship.toml.bak."$(date +%s)"
fi
cp starship.toml ~/.config/starship.toml
```

The Neovim and VS Code descriptors select their Dracula plugins in a local installation. Omarchy excludes root Lua files and `vscode.json` from Git-installed themes; those installations use the palette-generated editor themes instead. Locally, `vscode.json` takes precedence over the generated VS Code theme.

## Notes from the crypt

- This edition targets Quattro, not the old Waybar/Walker/Hyprlock desktop stack. The former `hyprlock.conf` is preserved in `.legacy-archive/pre-quattro/`, outside normal theme staging.
- The Flat Dracula filenames on existing assets are historical, not a second theme you need to install.
- Wallpaper renderers, SVG sources, tests, and buildout tools are maintained separately; they are not required to use the theme.
- Original theme configuration and documentation are under the MIT license; see `LICENSE`.

## Attribution

Dracula Classic palette and specification:

https://draculatheme.com/spec

Base24 interpretation and Dracula Reborn adaptation by **OldJobobo**. Derived maroon follows Tinted Theming’s Dracula mapping:

https://github.com/tinted-theming/schemes

Omarchy wordmark and boot-unlock artwork, recolored for Dracula:

https://github.com/basecamp/omarchy

Hero stag silhouette: **Vecteezy, asset 60382207**.

Vencord styling follows Dracula’s adaptation of **Midnight by refact0r**:

https://github.com/refact0r/midnight-discord

---

*Stay as long as you like. We keep unusual hours.*
