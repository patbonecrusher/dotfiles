-- Hammerspoon config — managed by chezmoi (source: dot_hammerspoon/init.lua → ~/.hammerspoon/init.lua)
-- Requires Accessibility permission (System Settings → Privacy & Security → Accessibility).
--
-- All shortcuts use the Hyper modifier ⌃⌥⌘ (Ctrl+Alt+Cmd). Karabiner-Elements maps
-- Caps Lock (held) → ⌃⌥⌘, so e.g. Caps+H == ⌃⌥⌘H. To add a shortcut, write its
-- action function and add ONE row to the `binds` table below — the cheatsheet
-- (⌃⌥⌘H) is generated from that table, so it never drifts out of sync.

local HYPER = { "ctrl", "alt", "cmd" }
local binds -- forward declaration (the cheatsheet reads it; the binds reference actions)

-- Helpers -------------------------------------------------------------------
-- POSIX paths of the current Finder selection ({} if Finder isn't front / empty).
local function finderSelection()
  local script = [[
    tell application "Finder"
      set theSelection to selection
      set thePaths to {}
      repeat with anItem in theSelection
        set end of thePaths to POSIX path of (anItem as alias)
      end repeat
      return thePaths
    end tell
  ]]
  local ok, result = hs.osascript.applescript(script)
  if not ok or type(result) ~= "table" then return {} end
  return result
end

-- Actions -------------------------------------------------------------------

-- Reset Universal Control when the shared cursor gets trapped on the other Mac.
-- -9 (SIGKILL) is required: UniversalControl traps SIGTERM and survives a plain
-- kill. launchd relaunches it immediately, which frees the trapped cursor. Bind
-- the SAME hotkey on both Macs so it works no matter which one is stuck.
local function ucReset()
  hs.execute("killall -9 UniversalControl", true)
  hs.alert.show("↩︎ Universal Control reset")
end

-- Sleep the display immediately, even when an app (e.g. Factorio via
-- SDL_DisableScreenSaver) holds a PreventUserIdleDisplaySleep assertion that
-- blocks the normal timeout. `pmset` is in /usr/bin, off Hammerspoon's PATH.
local function displaySleep()
  hs.execute("/usr/bin/pmset displaysleepnow")
  hs.alert.show("󰤄 Display sleeping")
end

-- Open the current Finder folder in Gen Grabber: a selected folder/disk, the
-- container of a selected file, or (nothing selected) the front window's folder.
local function genGrabber()
  local script = [[
    tell application "Finder"
      if (count of (selection as list)) > 0 then
        set theItem to item 1 of (selection as list)
        if class of theItem is folder or class of theItem is disk then
          set p to (theItem as alias)
        else
          set p to (container of theItem as alias)   -- a file → its folder
        end if
      else
        set p to (target of front window as alias)    -- nothing selected → window's folder
      end if
      return POSIX path of p
    end tell
  ]]
  local ok, path = hs.osascript.applescript(script)
  if ok and path then
    local function shquote(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
    hs.execute("/usr/bin/open -b com.gengrabber.GenGrabber " .. shquote(path))
    hs.alert.show("Gen Grabber → " .. path:gsub("/$", ""):match("[^/]+$"))
  else
    hs.alert.show("No Finder folder to open")
  end
end

-- Open the current Finder selection in MassRename. Each path is passed as argv
-- (via `open -n -a … --args`), so names with spaces/special chars need no escaping.
local MASS_RENAME_APP = "/Applications/MassRename.app"
local function massRename()
  local paths = finderSelection()
  if #paths == 0 then
    hs.alert.show("Mass Rename: no files selected in Finder")
    return
  end
  local args = { "-n", "-a", MASS_RENAME_APP, "--args" }
  for _, p in ipairs(paths) do args[#args + 1] = p end
  hs.task.new("/usr/bin/open", nil, args):start()
  hs.alert.show("Mass Rename → " .. #paths .. (#paths == 1 and " item" or " items"))
end

-- Toggle an on-screen cheatsheet of every Hyper shortcut, generated from `binds`.
-- ⌃⌥⌘H (or Esc) dismisses it.
local cheatsheetShown = false
local escTap
local function toggleCheatsheet()
  if cheatsheetShown then
    hs.alert.closeAll()
    cheatsheetShown = false
    if escTap then escTap:stop(); escTap = nil end
    return
  end
  local lines = { "  Hammerspoon — Hyper shortcuts  (hold Caps = ⌃⌥⌘)", "" }
  for _, b in ipairs(binds) do
    lines[#lines + 1] = string.format("  ⌃⌥⌘%s   %s", b.key, b.desc)
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "  press ⌃⌥⌘H or Esc to dismiss"
  hs.alert.show(table.concat(lines, "\n"),
    { textFont = "Menlo", textSize = 16, radius = 12, strokeWidth = 2 },
    hs.screen.mainScreen(), 3600)
  cheatsheetShown = true
  -- Close on Escape (keycode 53) while the sheet is up.
  escTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
    if e:getKeyCode() == 53 then toggleCheatsheet(); return true end
    return false
  end):start()
end

-- Registry — the single source of truth for hotkeys AND the cheatsheet --------
binds = {
  { key = "H", desc = "Show this cheatsheet",                    fn = toggleCheatsheet },
  { key = "U", desc = "Reset Universal Control (unstick cursor)", fn = ucReset },
  { key = "S", desc = "Sleep display now",                       fn = displaySleep },
  { key = "G", desc = "Open current Finder folder in Gen Grabber", fn = genGrabber },
  { key = "R", desc = "Open Finder selection in MassRename",      fn = massRename },
}

for _, b in ipairs(binds) do
  hs.hotkey.bind(HYPER, b.key, b.fn)
end

-- Auto-reload this config whenever a .lua file here changes ------------------
hs.configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end):start()

hs.alert.show("Hammerspoon config loaded")
