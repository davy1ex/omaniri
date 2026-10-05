#!/bin/bash
# Non-destructive checks for Niri Extras. Changes nothing: it only validates the
# manifest, compiles the Lua, checks the toggle script, and (when the plugin is
# installed and on) asserts every binding it promises is actually registered.
#
#   bash tests/smoke.sh

set -uo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TOGGLE="$REPO/bin/niri-extras-toggle"
fail=0

ok() { printf 'ok   %s\n' "$*"; }
bad() { printf 'FAIL %s\n' "$*"; fail=1; }

# ---- static ----------------------------------------------------------------
if command -v omarchy >/dev/null 2>&1; then
  if omarchy plugin validate "$REPO" >/dev/null 2>&1; then ok "manifest validates"; else bad "manifest invalid"; fi
else
  echo "skip manifest (no omarchy)"
fi

if command -v luac >/dev/null 2>&1; then
  if luac -p "$REPO/hypr/niri-extras.lua" >/dev/null 2>&1; then ok "lua compiles"; else bad "lua syntax"; fi
else
  echo "skip lua (no luac)"
fi

if bash -n "$TOGGLE" 2>/dev/null; then ok "toggle bash syntax"; else bad "toggle bash syntax"; fi

status="$(bash "$TOGGLE" extras status 2>/dev/null)"
case "$status" in
  on | off) ok "toggle status: $status" ;;
  *) bad "toggle status: '$status'" ;;
esac

# ---- live (only when Hyprland is running and the config is on) --------------
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  if [[ $status == on ]]; then
    binds="$(hyprctl binds -j 2>/dev/null)"
    for desc in \
      "Focus left" "Focus down" "Focus up" "Focus right" \
      "Move window left" "Move window down" "Move window up" "Move window right" \
      "Narrow column" "Widen column" "Center column" \
      "Fake fullscreen" "Full screen" "Toggle scrolling/dwindle layout"; do
      if jq -e --arg d "$desc" 'any(.[]; .description == $d)' <<<"$binds" >/dev/null 2>&1; then
        ok "bind: $desc"
      else
        bad "bind missing: $desc"
      fi
    done

    errs="$(hyprctl configerrors 2>/dev/null)"
    if [[ -z $errs ]]; then ok "hyprctl configerrors clean"; else bad "configerrors: $errs"; fi
  else
    echo "skip bind checks (Niri Extras is off)"
  fi
else
  echo "skip bind checks (no Hyprland)"
fi

if ((fail)); then
  echo "---"
  echo "FAILED"
  exit 1
fi
echo "---"
echo "all good"
