# Niri Extras

Niri-style window management for Omarchy's **scrolling layout** — the pieces that
are missing from Omarchy's defaults and from the [Omari](https://github.com/chicreativetech/omari)
plugin.

It is a small **companion plugin**: it does not replace Omari. Install Omari for
the scrolling mode, gestures, workspace overview and Alt-Tab switcher, then add
Niri Extras for the window-handling details below. It also works on a stock
Omarchy scrolling layout with no other plugin installed.

## What it adds

| Keys | Action |
| --- | --- |
| `SUPER + H / J / K / L` | focus left / down / up / right (layout-aware, so it also works while a column is maximized) |
| `SUPER + SHIFT + H / J / K / L` | move / swap the window — **works even in fake-fullscreen** |
| `SUPER + -` / `SUPER + =` | narrow / widen the focused column by 10% — **persists across focus changes**, and shrinks straight out of fake-fullscreen |
| `SUPER + Shift + =` | widen (the `+` key) |
| `SUPER + C` | center the focused column |

The two fixes that Omari and Omarchy do not have:

- **Move while fake-fullscreen.** Hyprland refuses with `Can't swap fullscreen
  window`. Niri Extras briefly leaves fullscreen on every fullscreen window of
  the workspace, swaps, restores each window's exact state and refocuses — all
  synchronously in one frame, so nothing flickers.
- **Resize while fake-fullscreen, and make it stick.** A maximized window is
  re-applied to full width every time it regains focus, so a plain `colresize`
  is lost the moment you switch away and back. Niri Extras leaves fake-fullscreen
  on shrink and starts from 90%, so the width survives.

On any non-scrolling workspace (dwindle/master) it falls back to the usual
`focus` / `resize` dispatchers, so it never raises "no such layoutmsg".

## Requirements

- Omarchy with the Quattro shell and the `omarchy plugin` commands.
- Hyprland with Lua configuration and the built-in **scrolling** layout.
- A Nerd Font for the bar glyph.
- No other dependency, no remote build, no privileged command, no network
  request. It runs inside the existing Omarchy shell with your permissions.

## Install

```sh
omarchy plugin add https://github.com/davy1ex/niri-extras.git --enable
```

Then click the **Niri Extras** glyph on the bar (or right-click it) to turn the
bindings on. It is off until you switch it on, so nothing is written to your
configuration without consent.

CLI equivalent:

```sh
bash ~/.config/omarchy/plugins/io.github.davy1ex.niri-extras/bin/niri-extras-toggle extras on
```

## Remove

```sh
omarchy plugin remove io.github.davy1ex.niri-extras --yes
```

or turn it off first so its Hyprland config is removed from the toggles
directory:

```sh
bash ~/.config/omarchy/plugins/io.github.davy1ex.niri-extras/bin/niri-extras-toggle extras off
```

## How it works

Turning it on copies `hypr/niri-extras.lua` into
`~/.local/state/omarchy/toggles/hypr/niri-extras.lua`, the directory Omarchy's
default toggle loader (`default.hypr.toggles`) sources on every reload, then
runs `hyprctl reload`. Turning it off removes the file. No file under
`~/.config/hypr` is edited.

## Credits

Inspired by [Omari](https://github.com/chicreativetech/omari) (MIT) for the
layout-aware focus approach and the toggle-loader mechanism, and by the
[Niri](https://github.com/YaLTeR/niri) compositor for the interaction model.

## License

MIT — see [LICENSE](LICENSE).
