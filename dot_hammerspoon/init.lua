-- Hammerspoon config — managed by chezmoi (source: dot_hammerspoon/init.lua → ~/.hammerspoon/init.lua)
-- Requires Accessibility permission (System Settings → Privacy & Security → Accessibility).

-- Universal Control recovery ------------------------------------------------
-- The shared cursor sometimes crosses to the other Mac and gets trapped: you
-- can't drag it back because the keyboard/pointer now belong to the far Mac.
-- Press Ctrl+Alt+Cmd+U on whichever Mac holds the stuck cursor to restart the
-- UniversalControl daemon (it relaunches itself) and free it. Bind the SAME
-- hotkey on both Macs so it works no matter which one is trapped.
-- -9 (SIGKILL) is required: UniversalControl traps SIGTERM and survives a plain
-- kill. launchd relaunches it immediately, which frees the trapped cursor.
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "U", function()
  hs.execute("killall -9 UniversalControl", true)
  hs.alert.show("↩︎ Universal Control reset")
end)

-- Force display to sleep now -------------------------------------------------
-- Ctrl+Alt+Cmd+S sleeps the display immediately, even when an app (e.g.
-- Factorio via SDL_DisableScreenSaver) holds a PreventUserIdleDisplaySleep
-- assertion that blocks the normal timeout / screen saver. `pmset` lives in
-- /usr/bin, which isn't on Hammerspoon's PATH, so call it by absolute path.
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "S", function()
  hs.execute("/usr/bin/pmset displaysleepnow")
  hs.alert.show("󰤄 Display sleeping")
end)

-- Open the current Finder folder in Gen Grabber -----------------------------
-- Ctrl+Alt+Cmd+G resolves the folder to hand off: a selected folder/disk, the
-- container of a selected file, or (nothing selected) the front window's folder.
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "G", function()
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
end)

-- Open the current Finder selection in MassRename ---------------------------
-- Ctrl+Alt+Cmd+R passes every selected file/folder to MassRename.app as argv
-- (via `open -n -a … --args`), so names with spaces/special chars need no
-- escaping. Does nothing if Finder isn't frontmost or nothing is selected.
local MASS_RENAME_APP = "/Applications/MassRename.app"

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

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "R", function()
  local paths = finderSelection()
  if #paths == 0 then
    hs.alert.show("Mass Rename: no files selected in Finder")
    return
  end
  local args = { "-n", "-a", MASS_RENAME_APP, "--args" }
  for _, p in ipairs(paths) do args[#args + 1] = p end
  hs.task.new("/usr/bin/open", nil, args):start()
  hs.alert.show("Mass Rename → " .. #paths .. (#paths == 1 and " item" or " items"))
end)

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
