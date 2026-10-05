-- Niri Extras -- Niri-style window management for Hyprland's scrolling layout.
--
-- This file is NOT loaded from ~/.config/hypr directly. The plugin's
-- bin/niri-extras-toggle copies it into
-- ~/.local/state/omarchy/toggles/hypr/niri-extras.lua, a directory Omarchy's
-- toggle loader (default.hypr.toggles, required from hyprland.lua) sources on
-- every reload. Turning the plugin off removes it again.
--
-- It replaces Omarchy's default bindings for the keys it uses, so it works on a
-- stock Omarchy scrolling layout and next to the Omari plugin alike. Keys whose
-- physical position matters are bound by keycode (code:20/21) so they work
-- under non-US layouts too.

-- ------------------------------------------------------------------ focus ---
-- On the scrolling layout movefocus no-ops while the focused column is
-- maximized/fullscreen, so use the layout's own focus message there and fall
-- back to movefocus on other layouts (dwindle/master).
local function focus_in(direction)
  return function()
    local window = hl.get_active_window()
    local workspace = (window and window.workspace) or hl.get_active_workspace()

    if workspace and workspace.tiled_layout == "scrolling" then
      hl.dispatch(hl.dsp.layout("focus " .. direction))
    else
      hl.dispatch(hl.dsp.focus({ direction = direction }))
    end
  end
end

hl.unbind("SUPER + H")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
o.bind("SUPER + H", "Focus left",  focus_in("l"))
o.bind("SUPER + J", "Focus down",  focus_in("d"))
o.bind("SUPER + K", "Focus up",    focus_in("u"))
o.bind("SUPER + L", "Focus right", focus_in("r"))

-- ----------------------------------------------------------- move / swap ---
-- Hyprland refuses to swap a window that is fullscreen or maximized ("Can't
-- swap fullscreen window"). Leave fullscreen on every fullscreen tiled window
-- on the workspace for the duration of the swap, then restore each window's
-- exact state. Everything runs synchronously in one handler, so the
-- intermediate frame is never drawn and there is no flicker.
local function swap_window(direction)
  local active = hl.get_active_window()
  if not active then
    return
  end

  local restore = {}

  for _, window in ipairs(hl.get_windows({ workspace = active.workspace })) do
    if not window.floating and (window.fullscreen ~= 0 or window.fullscreen_client ~= 0) then
      restore[#restore + 1] = { window = window, internal = window.fullscreen, client = window.fullscreen_client }
      hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0, window = window }))
    end
  end

  hl.dispatch(hl.dsp.window.swap({ direction = direction }))

  for _, state in ipairs(restore) do
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = state.internal, client = state.client, window = state.window }))
  end

  hl.dispatch(hl.dsp.focus({ window = active }))
end

hl.unbind("SUPER + SHIFT + H")
hl.unbind("SUPER + SHIFT + J")
hl.unbind("SUPER + SHIFT + K")
hl.unbind("SUPER + SHIFT + L")
o.bind("SUPER + SHIFT + H", "Move window left",  function() swap_window("l") end)
o.bind("SUPER + SHIFT + J", "Move window down",  function() swap_window("d") end)
o.bind("SUPER + SHIFT + K", "Move window up",    function() swap_window("u") end)
o.bind("SUPER + SHIFT + L", "Move window right", function() swap_window("r") end)

-- --------------------------------------------------------- column width ---
-- colresize changes the focused column's width in steps of 10% on the scrolling
-- layout. While a window is flagged fullscreen/maximized, Hyprland re-applies
-- full width every time the window regains focus, so the width would not stick:
-- leave fake-fullscreen on shrink and start from 90%. Growing a fullscreen
-- window has nothing to add, so it is a no-op.
local function resize_window_width(grow)
  local active = hl.get_active_window()
  if not active then
    return
  end

  local layout = active.workspace and active.workspace.tiled_layout
  local fullscreen = active.fullscreen ~= 0 or active.fullscreen_client ~= 0

  if layout == "scrolling" then
    if fullscreen then
      if not grow then
        hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0, window = active }))
        hl.dispatch(hl.dsp.layout("colresize 0.9"))
      end
      return
    end

    hl.dispatch(hl.dsp.layout("colresize " .. (grow and "+0.1" or "-0.1")))
    return
  end

  -- Fallback for dwindle/master. A fullscreen window refuses resize, so leave
  -- fullscreen first; don't re-maximize, or the resize would be undone.
  if fullscreen then
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0, window = active }))
  end

  hl.dispatch(hl.dsp.window.resize({ x = (grow and -100 or 100), y = 0, relative = true }))
end

-- Omarchy's defaults on these keycodes were "Expand/Shrink window left" and
-- "Expand window down"; the scrolling layout is where widths matter.
hl.unbind("SUPER + code:20")
hl.unbind("SUPER + code:21")
hl.unbind("SUPER + SHIFT + code:21")
o.bind("SUPER + code:20", "Narrow column", function() resize_window_width(false) end)
o.bind("SUPER + code:21", "Widen column",  function() resize_window_width(true) end)
o.bind("SUPER + SHIFT + code:21", "Widen column", function() resize_window_width(true) end)

-- --------------------------------------------------------------- center ---
-- Niri's Mod+C. Only the scrolling layout has a center concept, so stay silent
-- elsewhere instead of raising "no such layoutmsg".
hl.unbind("SUPER + C")
o.bind("SUPER + C", "Center column", function()
  local window = hl.get_active_window()
  local workspace = (window and window.workspace) or hl.get_active_workspace()

  if workspace and workspace.tiled_layout == "scrolling" then
    hl.dispatch(hl.dsp.layout("center"))
  end
end)
